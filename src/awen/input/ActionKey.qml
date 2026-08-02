import QtQml

// An action mapping held keyboard keys onto an axis: positive and negative
// carry Qt.Key codes.
ActionDigital {
    id: root

    function keyPressed(key: int): bool {
        return root.press(key);
    }
    function keyReleased(key: int): bool {
        return root.release(key);
    }
}
