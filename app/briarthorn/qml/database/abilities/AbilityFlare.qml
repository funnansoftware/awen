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
}
