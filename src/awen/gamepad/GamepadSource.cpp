#include "Gamepad.h"

#include "GamepadBackend.h"
#include "GamepadTranslate.h"

#include <unordered_map>

#include <QGuiApplication>
#include <QQmlEngine>
#include <QString>
#include <QTimer>

#include <SDL3/SDL.h>

using awen::Gamepad;
using awen::GamepadEventKind;

// Enum parity with SDL. Gamepad.h defines Button/Axis with explicit literals so it
// needs no SDL include; assert here — the one desktop TU that has the SDL headers —
// that they still match SDL's constants, so a version bump that renumbers them
// fails the build instead of silently mistranslating input.
static_assert(static_cast<int>(Gamepad::Button::Unknown) == SDL_GAMEPAD_BUTTON_INVALID);
static_assert(static_cast<int>(Gamepad::Button::South) == SDL_GAMEPAD_BUTTON_SOUTH);
static_assert(static_cast<int>(Gamepad::Button::East) == SDL_GAMEPAD_BUTTON_EAST);
static_assert(static_cast<int>(Gamepad::Button::West) == SDL_GAMEPAD_BUTTON_WEST);
static_assert(static_cast<int>(Gamepad::Button::North) == SDL_GAMEPAD_BUTTON_NORTH);
static_assert(static_cast<int>(Gamepad::Button::Back) == SDL_GAMEPAD_BUTTON_BACK);
static_assert(static_cast<int>(Gamepad::Button::Guide) == SDL_GAMEPAD_BUTTON_GUIDE);
static_assert(static_cast<int>(Gamepad::Button::Start) == SDL_GAMEPAD_BUTTON_START);
static_assert(static_cast<int>(Gamepad::Button::LeftStick) == SDL_GAMEPAD_BUTTON_LEFT_STICK);
static_assert(static_cast<int>(Gamepad::Button::RightStick) == SDL_GAMEPAD_BUTTON_RIGHT_STICK);
static_assert(static_cast<int>(Gamepad::Button::LeftShoulder) == SDL_GAMEPAD_BUTTON_LEFT_SHOULDER);
static_assert(static_cast<int>(Gamepad::Button::RightShoulder) == SDL_GAMEPAD_BUTTON_RIGHT_SHOULDER);
static_assert(static_cast<int>(Gamepad::Button::DpadUp) == SDL_GAMEPAD_BUTTON_DPAD_UP);
static_assert(static_cast<int>(Gamepad::Button::DpadDown) == SDL_GAMEPAD_BUTTON_DPAD_DOWN);
static_assert(static_cast<int>(Gamepad::Button::DpadLeft) == SDL_GAMEPAD_BUTTON_DPAD_LEFT);
static_assert(static_cast<int>(Gamepad::Button::DpadRight) == SDL_GAMEPAD_BUTTON_DPAD_RIGHT);
static_assert(static_cast<int>(Gamepad::Button::Misc1) == SDL_GAMEPAD_BUTTON_MISC1);
static_assert(static_cast<int>(Gamepad::Button::RightPaddle1) == SDL_GAMEPAD_BUTTON_RIGHT_PADDLE1);
static_assert(static_cast<int>(Gamepad::Button::LeftPaddle1) == SDL_GAMEPAD_BUTTON_LEFT_PADDLE1);
static_assert(static_cast<int>(Gamepad::Button::RightPaddle2) == SDL_GAMEPAD_BUTTON_RIGHT_PADDLE2);
static_assert(static_cast<int>(Gamepad::Button::LeftPaddle2) == SDL_GAMEPAD_BUTTON_LEFT_PADDLE2);
static_assert(static_cast<int>(Gamepad::Button::Touchpad) == SDL_GAMEPAD_BUTTON_TOUCHPAD);
static_assert(static_cast<int>(Gamepad::Button::Misc2) == SDL_GAMEPAD_BUTTON_MISC2);
static_assert(static_cast<int>(Gamepad::Button::Misc3) == SDL_GAMEPAD_BUTTON_MISC3);
static_assert(static_cast<int>(Gamepad::Button::Misc4) == SDL_GAMEPAD_BUTTON_MISC4);
static_assert(static_cast<int>(Gamepad::Button::Misc5) == SDL_GAMEPAD_BUTTON_MISC5);
static_assert(static_cast<int>(Gamepad::Button::Misc6) == SDL_GAMEPAD_BUTTON_MISC6);

static_assert(static_cast<int>(Gamepad::Axis::Unknown) == SDL_GAMEPAD_AXIS_INVALID);
static_assert(static_cast<int>(Gamepad::Axis::LeftX) == SDL_GAMEPAD_AXIS_LEFTX);
static_assert(static_cast<int>(Gamepad::Axis::LeftY) == SDL_GAMEPAD_AXIS_LEFTY);
static_assert(static_cast<int>(Gamepad::Axis::RightX) == SDL_GAMEPAD_AXIS_RIGHTX);
static_assert(static_cast<int>(Gamepad::Axis::RightY) == SDL_GAMEPAD_AXIS_RIGHTY);
static_assert(static_cast<int>(Gamepad::Axis::LeftTrigger) == SDL_GAMEPAD_AXIS_LEFT_TRIGGER);
static_assert(static_cast<int>(Gamepad::Axis::RightTrigger) == SDL_GAMEPAD_AXIS_RIGHT_TRIGGER);

namespace
{
    // The poll cadence while a controller is connected and the app is active. SDL
    // needs its queue drained regularly to surface events; an interval of 0 would
    // spin a whole CPU core, so we pump a little faster than the display refreshes
    // (~125 Hz) — well under one frame of input lag.
    constexpr auto PollIntervalMs = 8;

    // The slow heartbeat used when there is nothing to poll for at full speed — no
    // controller connected, or the window is not active. Still frequent enough to
    // surface a hotplug within a fraction of a second, but it stops an idle or
    // backgrounded app waking the main thread ~125x/s.
    constexpr auto IdlePollIntervalMs = 250;

    /// @brief The single owner of SDL's gamepad subsystem for one QML engine.
    ///
    /// SDL_PollEvent drains one process-global queue, so exactly one of these pumps
    /// it (on a timer) and holds the open SDL_Gamepad handles; it broadcasts raw
    /// events, which the Gamepad attached instances forward to their items as typed
    /// signals. Parented to the engine, so SDL is torn down with it. Reached only
    /// via sourceFor().
    class GamepadSource : public QObject
    {
        Q_OBJECT

    public:
        explicit GamepadSource(QObject* parent = nullptr) : QObject{parent}
        {
            if (!SDL_Init(SDL_INIT_GAMEPAD))
            {
                qWarning("awen.gamepad: failed to initialise SDL gamepad subsystem: %s", SDL_GetError());
                return;
            }
            initialized_ = true;

            timer_ = new QTimer{this};
            connect(timer_, &QTimer::timeout, this, &GamepadSource::poll);
            timer_->start(PollIntervalMs);
            // Re-evaluate the cadence whenever the app gains/loses active state, so a
            // backgrounded or unfocused window drops to the heartbeat promptly rather
            // than only on the next poll.
            connect(qApp, &QGuiApplication::applicationStateChanged, this, [this] { updatePollRate(); });
            // Drain once now to open any controller already attached at startup and
            // settle on the correct rate (poll() ends in updatePollRate()).
            poll();
        }

        ~GamepadSource() override
        {
            for (const auto& entry : gamepads_)
            {
                SDL_CloseGamepad(entry.second);
            }
            // Mirror the scoped SDL_Init: SDL_QuitSubSystem honours SDL's per-subsystem
            // reference count and is the library-safe counterpart to the global
            // SDL_Quit (documented as unwise from a shared library). Only quit the
            // subsystem this instance actually brought up.
            if (initialized_)
            {
                SDL_QuitSubSystem(SDL_INIT_GAMEPAD);
            }
        }

        /// @brief Whether SDL_Init succeeded. A failed source is inert (no poll
        /// timer) and is dropped rather than cached by sourceFor(), so a later
        /// attach retries.
        [[nodiscard]] auto initialized() const -> bool
        {
            return initialized_;
        }

    signals:
        void connected(int deviceId);
        void disconnected(int deviceId);
        void buttonPressed(int deviceId, int button);
        void buttonReleased(int deviceId, int button);
        void axisChanged(int deviceId, int axis, double value);

    private:
        // Drain SDL's event queue: the pure decode says what each event is, this
        // acts on it (open/close on hotplug, broadcast button/axis). Called by the
        // poll timer.
        auto poll() -> void
        {
            auto event = SDL_Event{};
            while (SDL_PollEvent(&event))
            {
                const auto decoded = awen::decodeEvent(event);
                if (!decoded)
                {
                    continue;
                }

                switch (decoded->kind)
                {
                    case GamepadEventKind::Connected:
                        open(static_cast<SDL_JoystickID>(decoded->deviceId));
                        break;
                    case GamepadEventKind::Disconnected:
                        close(static_cast<SDL_JoystickID>(decoded->deviceId));
                        break;
                    case GamepadEventKind::ButtonPressed:
                        emit buttonPressed(decoded->deviceId, decoded->code);
                        break;
                    case GamepadEventKind::ButtonReleased:
                        emit buttonReleased(decoded->deviceId, decoded->code);
                        break;
                    case GamepadEventKind::AxisMotion:
                        emit axisChanged(decoded->deviceId, decoded->code, decoded->value);
                        break;
                }
            }

            updatePollRate();
        }

        // SDL re-announces devices already attached at startup, so this fires for
        // them too once we begin polling. Open each one once.
        auto open(SDL_JoystickID id) -> void
        {
            if (gamepads_.contains(id))
            {
                return;
            }

            SDL_Gamepad* pad = SDL_OpenGamepad(id);
            if (pad == nullptr)
            {
                qWarning("awen.gamepad: failed to open gamepad %u: %s", static_cast<unsigned>(id), SDL_GetError());
                return;
            }

            gamepads_.emplace(id, pad);
            emit connected(static_cast<int>(id));
        }

        auto close(SDL_JoystickID id) -> void
        {
            const auto it = gamepads_.find(id);
            if (it == gamepads_.end())
            {
                return;
            }

            SDL_CloseGamepad(it->second);
            gamepads_.erase(it);
            emit disconnected(static_cast<int>(id));
        }

        // Drop to the slow heartbeat whenever there is nothing to poll for at full
        // speed — no controller connected, or the app is not the active window — and
        // raise back as soon as a controller is connected and the app is active.
        auto updatePollRate() -> void
        {
            const auto active = QGuiApplication::applicationState() == Qt::ApplicationActive;
            timer_->setInterval(!gamepads_.empty() && active ? PollIntervalMs : IdlePollIntervalMs);
        }

        QTimer* timer_ = nullptr;
        bool initialized_ = false;
        std::unordered_map<SDL_JoystickID, SDL_Gamepad*> gamepads_;
    };

    // The one source for the engine that owns @p attachee, created on first need and
    // parented to that engine. findChild is the registry — we only ever make one per
    // engine.
    auto sourceFor(QObject* attachee) -> GamepadSource*
    {
        QQmlEngine* engine = qmlEngine(attachee);
        if (engine == nullptr)
        {
            return nullptr;
        }

        auto* source = engine->findChild<GamepadSource*>(QString{}, Qt::FindDirectChildrenOnly);
        if (source == nullptr)
        {
            source = new GamepadSource{engine};
            if (!source->initialized())
            {
                // SDL init failed: drop the inert source instead of caching it on the
                // engine forever, so a later attach can retry rather than wiring
                // listeners to a source that will never emit.
                delete source;
                return nullptr;
            }
        }
        return source;
    }
}

auto awen::attachGamepad(Gamepad* gamepad, QObject* attachee) -> void
{
    // Each attached instance is one listener on the shared source. Connection and
    // removal pass straight through; button and axis events are re-emitted with the
    // Gamepad type's enums so handlers receive Gamepad.Button.* / Gamepad.Axis.*.
    GamepadSource* source = sourceFor(attachee);
    if (source == nullptr)
    {
        return;
    }

    QObject::connect(source, &GamepadSource::connected, gamepad, &Gamepad::connected);
    QObject::connect(source, &GamepadSource::disconnected, gamepad, &Gamepad::disconnected);
    QObject::connect(source, &GamepadSource::buttonPressed, gamepad,
                     [gamepad](int deviceId, int button) { emit gamepad->buttonPressed(deviceId, static_cast<Gamepad::Button>(button)); });
    QObject::connect(source, &GamepadSource::buttonReleased, gamepad,
                     [gamepad](int deviceId, int button) { emit gamepad->buttonReleased(deviceId, static_cast<Gamepad::Button>(button)); });
    QObject::connect(source, &GamepadSource::axisChanged, gamepad, [gamepad](int deviceId, int axis, double value)
                     { emit gamepad->axisChanged(deviceId, static_cast<Gamepad::Axis>(axis), value); });
}

#include "GamepadSource.moc"
