import QtQml
import awen.gamepad
import ".."

// The kinetic rack: four dumb slugs, cheap to cycle but aimed by the pilot.
AbilityLaunch {
    name: "kinetic"
    label: qsTr("KINETIC")
    cooldown: 2
    charges: 4
    weapon: Classification.Kind.MissileKinetic
    defaultKey: Qt.Key_E
    defaultButton: Gamepad.Button.West
}
