import QtQml

// An action mapping held controller buttons onto an axis: positive and
// negative carry button codes, awen.gamepad's Gamepad.Button values.
ActionDigital {
    id: root

    function buttonPressed(button: int): bool {
        return root.press(button);
    }
    function buttonReleased(button: int): bool {
        return root.release(button);
    }
}
