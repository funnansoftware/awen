import QtQuick
import ".."

// Presentation-only: the mount the stores page draws the cannon's station
// with — what sits on the airframe is the turret, not the round it throws.
// Nothing spawns it and no sensor ever returns it.
Data {
    id: root

    classification: Classification.Kind.Turret
    // A squat housing with the barrel out the nose, on the symbol frame's
    // own nose-up axis.
    outline: [Qt.point(-0.06, -0.5), Qt.point(0.06, -0.5), Qt.point(0.06, -0.14), Qt.point(0.3, -0.14), Qt.point(0.3, 0.34), Qt.point(-0.3, 0.34), Qt.point(-0.3, -0.14), Qt.point(-0.06, -0.14)]
    label: qsTr("GUN")
    symbolScale: 0.7
}
