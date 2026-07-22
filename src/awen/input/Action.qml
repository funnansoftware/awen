import QtQml

// Base type for an input action: one input source bound onto an axis,
// contributing this action's value whenever it changes. Derive and override
// the handlers for the channel the action listens on; each returns whether
// the event was consumed.
QtObject {
    id: action

    // The axis this action drives; named control because ActionAxis uses
    // axis for the source axis code.
    required property Axis control

    // This action's contribution to the axis.
    property real value: 0

    onValueChanged: action.control.contribute(action, action.value)

    // Returns the action to rest; Actions.reset() fans this out on focus
    // loss, where release events are never delivered and state would stick.
    function reset() {
        action.value = 0;
    }

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
