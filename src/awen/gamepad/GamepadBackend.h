#pragma once

class QObject;

namespace awen
{
    class Gamepad;

    /// @brief Wire @p gamepad's signals to the gamepad source owned by the QML
    /// engine that owns @p attachee.
    ///
    /// The SDL backend (GamepadSource.cpp) drives it on desktop and wasm (in the
    /// browser SDL's joystick backend wraps the Gamepad API); android provides
    /// an inert implementation (GamepadStub.cpp) — no source, no events.
    /// @param gamepad The attached instance to feed.
    /// @param attachee The QML object the instance is attached to; its engine owns the shared source.
    auto attachGamepad(Gamepad* gamepad, QObject* attachee) -> void;
}
