import QtQml
import awen.gamepad
import ".."

// The kinetic rack: four dumb slugs, cheap to cycle but aimed by the pilot.
AbilityLaunch {
    id: root

    name: "kinetic"
    label: qsTr("KINETIC")
    cooldown: 2
    charges: 4
    weapon: Classification.Kind.MissileKinetic
    defaultKey: Qt.Key_E
    defaultButton: Gamepad.Button.West
    // One station per slug on the fuselage cheeks.
    stations: [Qt.point(-0.1, -0.05), Qt.point(-0.1, 0.07), Qt.point(0.1, -0.05), Qt.point(0.1, 0.07)]
}
