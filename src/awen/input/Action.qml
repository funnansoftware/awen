import QtQml

// Base type for an input action: one input source bound onto an axis,
// contributing this action's value whenever it changes. Derive and override
// the handlers for the channel the action listens on; each returns whether
// the event was consumed.
QtObject {
    id: root

    // The axis this action drives; named control because ActionAxis uses
    // axis for the source axis code.
    required property Axis control

    // This action's contribution to the axis.
    property real value: 0

    onValueChanged: root.control.contribute(root, root.value)

    // Returns the action to rest; Actions.reset() fans this out on focus
    // loss, where release events are never delivered and state would stick.
    function reset() {
        root.value = 0;
    }

    // Re-states what the source is saying right now, with no event to prompt
    // it — for a handover where the router goes on listening and rest would be
    // a lie about a control the player is still holding. Nothing by default:
    // a digital source speaks in edges, and an edge that has already been and
    // gone cannot be read back off the device, which is exactly why reset() is
    // the honest answer for one. An absolute source overrides this.
    function resync() {}

    function keyPressed(key: int): bool {
        return false;
    }
    function keyReleased(key: int): bool {
        return false;
    }
    function buttonPressed(button: int): bool {
        return false;
    }
    function buttonReleased(button: int): bool {
        return false;
    }
    function axisMoved(axis: int, position: real): bool {
        return false;
    }
}
