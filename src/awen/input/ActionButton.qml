import QtQml

// An action mapping held controller buttons onto an axis: positive and
// negative carry button codes, awen.gamepad's Gamepad.Button values.
ActionDigital {
    id: action

    function buttonPressed(button: int): bool {
        return action.press(button);
    }
    function buttonReleased(button: int): bool {
        return action.release(button);
    }
}
