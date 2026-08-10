import QtQml
import awen.gamepad
import ".."

// The flare pod: ten decoys, popped one at a time off no cooldown, each
// thrown 2 km toward the round it answers and burning there for ten seconds.
AbilityCountermeasure {
    id: root

    name: "flare"
    label: qsTr("FLARE")
    charges: 10
    decoy: Classification.Kind.Decoy
    life: 10
    ejectRange: 2000
    defaultKey: Qt.Key_F
    defaultButton: Gamepad.Button.South
    // A dispenser pair aft, not a pip per round: the pod is a magazine, and
    // ten glyphs would out-clutter the racks beside it.
    stations: [Qt.point(-0.06, 0.42), Qt.point(0.06, 0.42)]
}
