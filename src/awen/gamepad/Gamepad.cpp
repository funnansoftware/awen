#include "Gamepad.h"

#include "GamepadBackend.h"

using awen::Gamepad;

Gamepad::Gamepad(QObject* parent) : QObject{parent}
{
    // The backend — SDL on desktop, inert on wasm/android — connects this instance
    // to the shared, engine-owned source; button and axis events arrive re-emitted
    // as this type's Button/Axis enums.
    awen::attachGamepad(this, parent);
}

auto Gamepad::qmlAttachedProperties(QObject* object) -> Gamepad*
{
    return new Gamepad{object};
}
