import QtQml

// An action mapping an analogue source axis onto the driven axis: the raw
// position is deadened around rest, then scaled — negative scale inverts.
Action {
    id: root

    // The axis listened to, awen.gamepad's Gamepad.Axis values.
    required property int axis

    // Multiplier applied after the deadzone; negative flips direction.
    property real scale: 1

    // Positions closer to rest than this fold to zero, absorbing stick jitter.
    property real deadzone: 0.15

    // Where the source last reported itself. A stick states a level rather
    // than an edge, and states it only when it moves — a stick pushed to its
    // stop and held there emits nothing at all — so this is the whole record
    // of where the control is, and the only thing resync() can read it back
    // from.
    property real position: 0

    function axisMoved(moved: int, reading: real): bool {
        if (moved !== root.axis)
            return false;
        root.position = reading;
        root.resync();
        return true;
    }

    // The one place the raw position becomes a contribution, so re-stating the
    // stick and hearing it move cannot map it two different ways.
    function resync() {
        root.value = (Math.abs(root.position) < root.deadzone ? 0 : root.position) * root.scale;
    }
}
