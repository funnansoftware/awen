#pragma once

class QObject;

namespace awen
{
    class Gamepad;

    /// @brief Wire @p gamepad's signals to the gamepad source owned by the QML
    /// engine that owns @p attachee.
    ///
    /// The desktop backend (GamepadSource.cpp) drives it from SDL; wasm/android
    /// provide an inert implementation (GamepadStub.cpp) — no source, no events.
    /// @param gamepad The attached instance to feed.
    /// @param attachee The QML object the instance is attached to; its engine owns the shared source.
    auto attachGamepad(Gamepad* gamepad, QObject* attachee) -> void;
}
