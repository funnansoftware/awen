import QtQml

// An action mapping an analogue source axis onto the driven axis: the raw
// position is deadened around rest, then scaled — negative scale inverts.
Action {
    id: action

    // The axis listened to, awen.gamepad's Gamepad.Axis values.
    required property int axis

    // Multiplier applied after the deadzone; negative flips direction.
    property real scale: 1

    // Positions closer to rest than this fold to zero, absorbing stick jitter.
    property real deadzone: 0.15

    function axisMoved(moved: int, position: real): bool {
        if (moved !== action.axis)
            return false;
        action.value = (Math.abs(position) < action.deadzone ? 0 : position) * action.scale;
        return true;
    }
}
