import QtQuick
import ".."

// Fast, manoeuvrable combat aircraft — the airframe both sides fly in the
// duel. Mid-range across the board, with both missile racks and a flare pod.
DataEntity {
    id: root

    classification: Classification.Kind.AircraftFighter
    outline: [Qt.point(0, -0.5), Qt.point(0.4, 0.45), Qt.point(0, 0.18), Qt.point(-0.4, 0.45)]
    // The stores page's plan view: nose, fuselage cheeks, swept wings to the
    // outline's own (±0.4, 0.45) tips, a trailing-edge notch and the tail.
    silhouette: [Qt.point(0, -0.5), Qt.point(0.05, -0.32), Qt.point(0.06, -0.13), Qt.point(0.4, 0.28), Qt.point(0.4, 0.34), Qt.point(0.07, 0.3), Qt.point(0.06, 0.4), Qt.point(0.14, 0.48), Qt.point(0.03, 0.44), Qt.point(0, 0.5), Qt.point(-0.03, 0.44), Qt.point(-0.14, 0.48), Qt.point(-0.06, 0.4), Qt.point(-0.07, 0.3), Qt.point(-0.4, 0.34), Qt.point(-0.4, 0.28), Qt.point(-0.06, -0.13), Qt.point(-0.05, -0.32)]
    label: qsTr("FIGHTER")
    hullGauge: true

    // A +/- 60 degree radar cone: it has to point at what it wants to see, and
    // a semi-active round of its own only tracks what it keeps inside this.
    radarFov: 90

    stats: Stats {
        kinetic: 5
        maneuver: 7
        durable: 5
        compute: 6
        sensor: 6
        stealth: 5
    }

    abilities: ["guided", "kinetic", "flare"]
}
