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
    /// Unlike Keys, these fire regardless of focus: every attached item hears every
    /// connected device (told apart by @p deviceId). The attached instances share
    /// one engine-owned SDL source (inert on android). Axis values are normalised:
    /// sticks [-1, 1] (Y negative upward), triggers [0, 1].
    class Gamepad : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Gamepad is only usable as an attached property (Gamepad.on...) and for its enums")
        QML_ATTACHED(Gamepad)

        /// @brief Milliseconds between input polls while a controller is connected
        /// and the app is active; clamped to at least 1. Engine-wide: all attached
        /// instances share one source, so the last write wins.
        Q_PROPERTY(int pollInterval READ pollInterval WRITE setPollInterval NOTIFY pollIntervalChanged)

        /// @brief Milliseconds between polls while no controller is connected or
        /// the app is inactive; clamped and engine-wide like pollInterval.
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

        /// @brief Default pollInterval: slightly faster than display refresh keeps
        /// input lag under one frame. On wasm 16 ms is enough — the browser only
        /// refreshes gamepad state once per animation frame.
        static constexpr auto DefaultPollInterval = std::chrono::milliseconds{8};

        /// @brief Default idlePollInterval: catches a hotplug quickly without
        /// waking an idle app ~125x/s.
        static constexpr auto DefaultIdlePollInterval = std::chrono::milliseconds{250};

        // Called by the QML engine to build the attached object for each item.
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
