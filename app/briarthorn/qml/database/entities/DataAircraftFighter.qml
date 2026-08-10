import QtQuick
import ".."

// Fast, manoeuvrable combat aircraft — the airframe both sides fly in the
// duel. Mid-range across the board, with both missile racks and a flare pod.
DataEntity {
    id: root

    classification: Classification.Kind.AircraftFighter
    outline: [Qt.point(0, -0.5), Qt.point(0.4, 0.45), Qt.point(0, 0.18), Qt.point(-0.4, 0.45)]
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
