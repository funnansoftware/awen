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

    /// @brief One decoded gamepad event: what happened, on which device, to which
    /// control, at what value. Free of Qt and SDL state so it unit-tests from
    /// synthetic events.
    struct GamepadEvent
    {
        GamepadEventKind kind; ///< The transition this event represents.
        int deviceId;          ///< SDL joystick instance id; stable while connected.
        int code{-1};          ///< Button (SDL_GamepadButton) or axis (SDL_GamepadAxis) code; -1 for (dis)connect.
        double value{0.0};     ///< Normalised axis value in [-1, 1]; 0 otherwise.
    };

    /// @brief Normalise a raw SDL axis reading (sticks [-32768, 32767], triggers
    /// [0, 32767]) by the positive extreme, clamping the stick range's one extra
    /// negative step.
    /// @param raw The raw SDL axis value.
    /// @return The normalised value in [-1, 1].
    auto normalizeAxis(int raw) -> double;

    /// @brief Decode one SDL event into a GamepadEvent.
    /// @param event The SDL event to decode.
    /// @return The decoded event, or std::nullopt if @p event is not a gamepad
    /// add/remove/button/axis event this module cares about.
    auto decodeEvent(const SDL_Event& event) -> std::optional<GamepadEvent>;
}
