#include "Gamepad.h"

#include "GamepadBackend.h"

using awen::Gamepad;

Gamepad::Gamepad(QObject* parent) : QObject{parent}
{
    // The backend — SDL on desktop and wasm, inert on android — connects this
    // instance to the shared, engine-owned source; button and axis events arrive
    // re-emitted as this type's Button/Axis enums.
    awen::attachGamepad(this, parent);
}

auto Gamepad::qmlAttachedProperties(QObject* object) -> Gamepad*
{
    // The QML engine takes ownership of the attached instance (parents it to
    // @p object), so returning a raw new is the required Qt contract.
    // NOLINTNEXTLINE(cppcoreguidelines-owning-memory)
    return new Gamepad{object};
}
