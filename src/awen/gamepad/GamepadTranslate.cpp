#include "GamepadTranslate.h"

#include <algorithm>

#include <SDL3/SDL_events.h>

using awen::GamepadEvent;
using awen::GamepadEventKind;

namespace
{
    // SDL reports stick axes in [-32768, 32767] and triggers in [0, 32767]; the
    // positive extreme normalises both.
    constexpr auto AxisScale = 32767.0;
}

auto awen::normalizeAxis(int raw) -> double
{
    return std::clamp(static_cast<double>(raw) / AxisScale, -1.0, 1.0);
}

auto awen::decodeEvent(const SDL_Event& event) -> std::optional<GamepadEvent>
{
    switch (event.type)
    {
        case SDL_EVENT_GAMEPAD_ADDED:
            return GamepadEvent{.kind = GamepadEventKind::Connected, .deviceId = static_cast<int>(event.gdevice.which)};

        case SDL_EVENT_GAMEPAD_REMOVED:
            return GamepadEvent{.kind = GamepadEventKind::Disconnected, .deviceId = static_cast<int>(event.gdevice.which)};

        case SDL_EVENT_GAMEPAD_BUTTON_DOWN:
            return GamepadEvent{
                .kind = GamepadEventKind::ButtonPressed, .deviceId = static_cast<int>(event.gbutton.which), .code = event.gbutton.button};

        case SDL_EVENT_GAMEPAD_BUTTON_UP:
            return GamepadEvent{
                .kind = GamepadEventKind::ButtonReleased, .deviceId = static_cast<int>(event.gbutton.which), .code = event.gbutton.button};

        case SDL_EVENT_GAMEPAD_AXIS_MOTION:
            return GamepadEvent{.kind = GamepadEventKind::AxisMotion,
                                .deviceId = static_cast<int>(event.gaxis.which),
                                .code = event.gaxis.axis,
                                .value = normalizeAxis(event.gaxis.value)};

        default:
            return std::nullopt;
    }
}
