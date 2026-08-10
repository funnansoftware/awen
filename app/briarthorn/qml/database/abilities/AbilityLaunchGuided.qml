import QtQml
import awen.gamepad
import ".."

// The guided rack: six fire-and-forget rounds, slow to cycle.
AbilityLaunch {
    id: root

    name: "guided"
    label: qsTr("GUIDED")
    cooldown: 2.5
    charges: 6
    weapon: Classification.Kind.MissileGuided
    defaultKey: Qt.Key_Space
    defaultButton: Gamepad.Button.RightShoulder
    // One station per round along the swept wings, outboard to inboard, on
    // the scope symbol's own delta.
    stations: [Qt.point(-0.31, 0.3), Qt.point(-0.23, 0.2), Qt.point(-0.14, 0.1), Qt.point(0.14, 0.1), Qt.point(0.23, 0.2), Qt.point(0.31, 0.3)]
}
