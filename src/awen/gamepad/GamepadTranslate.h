#pragma once

#include <cstdint>
#include <optional>

#include <SDL3/SDL_events.h>

namespace awen
{
    /// @brief The kind of input transition decoded from an SDL gamepad event.
    enum class GamepadEventKind : std::uint8_t
    {
        Connected,
        Disconnected,
        ButtonPressed,
        ButtonReleased,
        AxisMotion,
    };

    /// @brief A renderer-free view of one gamepad event: what happened, on which
    /// device, to which control, at what value.
    ///
    /// This is the device-agnostic core the QML layer forwards as typed signals.
    /// It is deliberately free of Qt and SDL state so it can be unit-tested from
    /// synthetic events with no hardware.
    struct GamepadEvent
    {
        GamepadEventKind kind; ///< The transition this event represents.
        int deviceId;          ///< SDL joystick instance id; stable while connected.
        int code = -1;         ///< Button (SDL_GamepadButton) or axis (SDL_GamepadAxis) code; -1 for (dis)connect.
        double value = 0.0;    ///< Normalised axis value in [-1, 1]; 0 otherwise.
    };

    /// @brief Normalise a raw SDL axis reading to [-1, 1].
    ///
    /// SDL reports stick axes in [-32768, 32767] and triggers in [0, 32767];
    /// dividing by the positive extreme normalises both (sticks to [-1, 1],
    /// triggers to [0, 1]), and the clamp keeps the one extra negative step a
    /// stick's range carries from landing just past -1.
    /// @param raw The raw SDL axis value.
    /// @return The normalised value, clamped to [-1, 1].
    auto normalizeAxis(int raw) -> double;

    /// @brief Decode one SDL event into a GamepadEvent.
    /// @param event The SDL event to decode.
    /// @return The decoded event, or std::nullopt if @p event is not a gamepad
    /// add/remove/button/axis event this module cares about.
    auto decodeEvent(const SDL_Event& event) -> std::optional<GamepadEvent>;
}
