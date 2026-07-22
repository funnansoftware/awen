import QtQml

// An action mapping held keyboard keys onto an axis: positive and negative
// carry Qt.Key codes.
ActionDigital {
    id: action

    function keyPressed(key: int): bool {
        return action.press(key);
    }
    function keyReleased(key: int): bool {
        return action.release(key);
    }
}
