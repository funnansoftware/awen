#include "Gamepad.h"

#include "GamepadBackend.h"
#include "GamepadTranslate.h"

#include <unordered_map>

#include <QGuiApplication>
#include <QQmlEngine>
#include <QString>
#include <QTimer>
#include <chrono>

#include <SDL3/SDL.h>

using awen::Gamepad;
using awen::GamepadEventKind;

// Gamepad.h defines Button/Axis with explicit literals so it stays SDL-free; assert
// here that they still match SDL's constants, so an SDL upgrade that renumbers them
// fails the build.
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
    /// @brief The single owner of SDL's gamepad subsystem for one QML engine: pumps
    /// SDL_PollEvent on a timer, holds the open handles, and broadcasts raw events
    /// to the Gamepad attached instances. Parented to the engine; reached via
    /// sourceFor().
    class GamepadSource : public QObject
    {
        Q_OBJECT

    public:
        Q_DISABLE_COPY_MOVE(GamepadSource)

        explicit GamepadSource(QObject* parent = nullptr) : QObject{parent}
        {
            if (!SDL_Init(SDL_INIT_GAMEPAD))
            {
                qWarning("awen.gamepad: failed to initialise SDL gamepad subsystem: %s", SDL_GetError());
                return;
            }
            initialized_ = true;

            // NOLINTNEXTLINE(cppcoreguidelines-owning-memory) — Qt parents the timer to this.
            timer_ = new QTimer{this};
            connect(timer_, &QTimer::timeout, this, &GamepadSource::poll);
            timer_->start(pollInterval_);
            // Drop to the idle heartbeat promptly when the app deactivates.
            connect(qApp, &QGuiApplication::applicationStateChanged, this, [this] { updatePollRate(); });
            // Drain once now to open any controller already attached at startup.
            poll();
        }

        ~GamepadSource() override
        {
            for (const auto& entry : gamepads_)
            {
                SDL_CloseGamepad(entry.second);
            }
            // SDL_QuitSubSystem honours SDL's per-subsystem refcount (SDL_Quit is
            // documented as unwise from a library); only quit what we brought up.
            if (initialized_)
            {
                SDL_QuitSubSystem(SDL_INIT_GAMEPAD);
            }
        }

        /// @brief Whether SDL_Init succeeded; a failed source is dropped by
        /// sourceFor() so a later attach retries.
        [[nodiscard]] auto initialized() const -> bool
        {
            return initialized_;
        }

        /// @brief Retune the connected-and-active poll cadence (Gamepad's
        /// pollInterval, already clamped there).
        auto setPollInterval(std::chrono::milliseconds interval) -> void
        {
            pollInterval_ = interval;
            updatePollRate();
        }

        /// @brief Retune the idle heartbeat cadence (Gamepad's idlePollInterval).
        auto setIdlePollInterval(std::chrono::milliseconds interval) -> void
        {
            idlePollInterval_ = interval;
            updatePollRate();
        }

    signals:
        // Commented parameter names: moc's generated definitions name them _t1/_t2
        // (real names trip clang-tidy's inconsistent-declaration-parameter-name,
        // bare ones trip named-parameter).
        void connected(int /*deviceId*/);
        void disconnected(int /*deviceId*/);
        void buttonPressed(int /*deviceId*/, int /*button*/);
        void buttonReleased(int /*deviceId*/, int /*button*/);
        void axisChanged(int /*deviceId*/, int /*axis*/, double /*value*/);

    private:
        // Drain SDL's queue: open/close on hotplug, broadcast button/axis events.
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

        // SDL re-announces devices already attached at startup; open each once.
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

        // Idle heartbeat when no pad is connected or the app is inactive.
        auto updatePollRate() -> void
        {
            const auto active = QGuiApplication::applicationState() == Qt::ApplicationActive;
            timer_->setInterval(!gamepads_.empty() && active ? pollInterval_ : idlePollInterval_);
        }

        QTimer* timer_{nullptr};
        bool initialized_{false};
        std::chrono::milliseconds pollInterval_{Gamepad::DefaultPollInterval};
        std::chrono::milliseconds idlePollInterval_{Gamepad::DefaultIdlePollInterval};
        std::unordered_map<SDL_JoystickID, SDL_Gamepad*> gamepads_;
    };

    // The one source for the engine that owns @p attachee, created on first need;
    // findChild is the registry.
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
            // Qt parents the source to the engine, which owns it thereafter.
            // NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
            source = new GamepadSource{engine};
            if (!source->initialized())
            {
                // SDL init failed: drop the inert source so a later attach retries.
                // NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
                delete source;
                return nullptr;
            }
        }
        return source;
    }
}

auto awen::attachGamepad(Gamepad* gamepad, QObject* attachee) -> void
{
    // Each attached instance is one listener on the shared source; button and axis
    // events are re-emitted with the Gamepad type's enums.
    auto* const source = sourceFor(attachee);
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

    // Cadence writes pass through to the shared source (engine-wide, last write
    // wins). Wired before QML can assign, so no initial push is needed.
    QObject::connect(gamepad, &Gamepad::pollIntervalChanged, source,
                     [source, gamepad] { source->setPollInterval(std::chrono::milliseconds{gamepad->pollInterval()}); });
    QObject::connect(gamepad, &Gamepad::idlePollIntervalChanged, source,
                     [source, gamepad] { source->setIdlePollInterval(std::chrono::milliseconds{gamepad->idlePollInterval()}); });
}

#include "GamepadSource.moc"
