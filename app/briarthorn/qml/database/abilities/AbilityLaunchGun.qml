import QtQml
import awen.gamepad
import ".."

// The gatling cannon: held down rather than pressed, streaming eight rounds
// a second off a deep magazine, unguided and short-legged — the close-combat
// complement to the racks.
AbilityLaunch {
    id: root

    name: "gun"
    label: qsTr("GUN")
    automatic: true
    cooldown: 0.125
    charges: 300
    weapon: Classification.Kind.Bullet
    // The station wears the mount rather than the round: one turret glyph
    // standing for the whole magazine, the way the flare dispensers do.
    stationKind: Classification.Kind.Turret
    defaultKey: Qt.Key_G
    defaultButton: Gamepad.Button.RightStick
    stations: [Qt.point(0, -0.28)]
}
