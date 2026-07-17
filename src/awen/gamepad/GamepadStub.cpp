#include "GamepadBackend.h"

// wasm/android: no SDL, so no gamepad source. The Gamepad attached type and its
// Button/Axis enums still register (so `import awen.gamepad` and Gamepad.Button.*
// resolve everywhere); attach is a no-op, so the signals simply never fire. The
// desktop backend lives in GamepadSource.cpp.
auto awen::attachGamepad(awen::Gamepad* /*gamepad*/, QObject* /*attachee*/) -> void
{
}
