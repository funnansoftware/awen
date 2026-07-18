#include "GamepadBackend.h"

// android: no SDL activity under androiddeployqt, so attach is a no-op — the type
// and enums still register, the signals just never fire.
auto awen::attachGamepad(awen::Gamepad* /*gamepad*/, QObject* /*attachee*/) -> void
{
}
