#pragma once

class QObject;

namespace awen
{
    class Gamepad;

    /// @brief Wire @p gamepad's signals to the engine-owned gamepad source. The SDL
    /// backend (GamepadSource.cpp) serves desktop and wasm; android gets the inert
    /// GamepadStub.cpp.
    /// @param gamepad The attached instance to feed.
    /// @param attachee The QML object the instance is attached to.
    auto attachGamepad(Gamepad* gamepad, QObject* attachee) -> void;
}
