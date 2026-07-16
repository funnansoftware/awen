import QtQuick
import briarthorn.quick

Window {
    id: root

    // Injected by quick::run via setInitialProperties before load.
    required property GameController game

    width: 800
    height: 600
    visible: true
    title: qsTr("briarthorn")
    color: "#505050" // the scope background

    WorldView {
        anchors.fill: parent
        game: root.game
        focus: true // route the window's keys (WASD/arrows/shift) to the game
    }
}
