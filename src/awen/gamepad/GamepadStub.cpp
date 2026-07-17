#include "GamepadBackend.h"

// android: no SDL activity under androiddeployqt, so no gamepad source. The
// Gamepad attached type and its Button/Axis enums still register (so
// `import awen.gamepad` and Gamepad.Button.* resolve everywhere); attach is a
// no-op, so the signals simply never fire, and the cadence properties
// (pollInterval/idlePollInterval) hold their values but drive nothing. The SDL
// backend for every other platform (desktop and wasm) lives in GamepadSource.cpp.
auto awen::attachGamepad(awen::Gamepad* /*gamepad*/, QObject* /*attachee*/) -> void
{
}
