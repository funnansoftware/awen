#pragma once

#include <chrono>
#include <cstdint>

#include <QtQml/qqmlregistration.h>
#include <QObject>

namespace awen
{
    /// @brief Gamepad input for QML, used as an attached property — like Keys.
    /// Attach handlers to any item:
    ///
    /// @code
    /// import awen.gamepad
    /// Item {
    ///     Gamepad.onAxisChanged: (deviceId, axis, value) => { ... }
    ///     Gamepad.onButtonPressed: (deviceId, button) => { ... }
    /// }
    /// @endcode
    ///
    /// Unlike Keys, these fire regardless of focus: gamepad input has no focus
    /// routing, so every attached item hears every connected device (told apart by
    /// @p deviceId, stable while connected). The type is never instantiated from
    /// QML — it exists for these attached signals and for its Button/Axis enums
    /// (e.g. Gamepad.Axis.LeftX). Following the Keys pattern it attaches an instance
    /// of itself to each item; those instances share one engine-owned SDL source
    /// behind the scenes (on wasm SDL wraps the browser's Gamepad API; android
    /// builds an inert source, so the type and enums exist but no events fire).
    /// Axis values are normalised: sticks [-1, 1] (Y negative upward), triggers
    /// [0, 1].
    ///
    /// The Button/Axis enumerators carry SDL's SDL_GamepadButton / SDL_GamepadAxis
    /// values as explicit literals so this header needs no SDL include; a build-time
    /// static_assert in the SDL backend keeps them in step with SDL.
    class Gamepad : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Gamepad is only usable as an attached property (Gamepad.on...) and for its enums")
        QML_ATTACHED(Gamepad)

        /// @brief Milliseconds between input polls while a controller is connected
        /// and the app is active. Defaults to DefaultPollInterval; clamped to at
        /// least 1 (an interval of 0 would spin the event loop).
        ///
        /// Engine-wide: every attached instance feeds one engine-owned source, so
        /// setting this on any item retunes the shared polling — last write wins;
        /// prefer setting it in one place. Inert on android (the stub backend has
        /// nothing to poll).
        Q_PROPERTY(int pollInterval READ pollInterval WRITE setPollInterval NOTIFY pollIntervalChanged)

        /// @brief Milliseconds between polls while there is nothing to poll for at
        /// full speed — no controller connected, or the app is not active. Defaults
        /// to DefaultIdlePollInterval; clamped and engine-wide like pollInterval.
        Q_PROPERTY(int idlePollInterval READ idlePollInterval WRITE setIdlePollInterval NOTIFY idlePollIntervalChanged)

    public:
        /// @brief A gamepad button, matching SDL's SDL_GamepadButton values.
        enum class Button : std::int8_t
        {
            Unknown = -1,
            South = 0,
            East = 1,
            West = 2,
            North = 3,
            Back = 4,
            Guide = 5,
            Start = 6,
            LeftStick = 7,
            RightStick = 8,
            LeftShoulder = 9,
            RightShoulder = 10,
            DpadUp = 11,
            DpadDown = 12,
            DpadLeft = 13,
            DpadRight = 14,
            Misc1 = 15,
            RightPaddle1 = 16,
            LeftPaddle1 = 17,
            RightPaddle2 = 18,
            LeftPaddle2 = 19,
            Touchpad = 20,
            Misc2 = 21,
            Misc3 = 22,
            Misc4 = 23,
            Misc5 = 24,
            Misc6 = 25,
        };
        Q_ENUM(Button)

        /// @brief A gamepad axis, matching SDL's SDL_GamepadAxis values.
        enum class Axis : std::int8_t
        {
            Unknown = -1,
            LeftX = 0,
            LeftY = 1,
            RightX = 2,
            RightY = 3,
            LeftTrigger = 4,
            RightTrigger = 5,
        };
        Q_ENUM(Axis)

        /// @brief Default pollInterval. SDL needs its queue drained regularly to
        /// surface events; a little faster than the display refreshes (~125 Hz)
        /// keeps input lag well under one frame. On wasm the browser only refreshes
        /// gamepad state at animation-frame rate, so one frame (16 ms) is the
        /// sensible setting there — faster only re-reads the same snapshot.
        static constexpr auto DefaultPollInterval = std::chrono::milliseconds{8};

        /// @brief Default idlePollInterval: frequent enough to surface a hotplug
        /// within a fraction of a second, without waking an idle or backgrounded
        /// app ~125x/s.
        static constexpr auto DefaultIdlePollInterval = std::chrono::milliseconds{250};

        // Used by the QML engine to build the attached object for each item. Not
        // called directly.
        explicit Gamepad(QObject* parent = nullptr);
        static auto qmlAttachedProperties(QObject* object) -> Gamepad*;

        [[nodiscard]] auto pollInterval() const -> int;
        auto setPollInterval(int intervalMs) -> void;

        [[nodiscard]] auto idlePollInterval() const -> int;
        auto setIdlePollInterval(int intervalMs) -> void;

    signals:
        /// @brief A controller was plugged in / unplugged. @p deviceId identifies
        /// it in the axis and button signals.
        void connected(int deviceId);
        void disconnected(int deviceId);

        void buttonPressed(int deviceId, Button button);
        void buttonReleased(int deviceId, Button button);

        /// @brief An axis moved. @p value is normalised: sticks [-1, 1] (Y negative
        /// upward), triggers [0, 1].
        void axisChanged(int deviceId, Axis axis, double value);

        void pollIntervalChanged();
        void idlePollIntervalChanged();

    private:
        std::chrono::milliseconds pollInterval_{DefaultPollInterval};         ///< See pollInterval.
        std::chrono::milliseconds idlePollInterval_{DefaultIdlePollInterval}; ///< See idlePollInterval.
    };
}
