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
    radarFov: 120

    stats: Stats {
        kinetic: 3 // 500 m/s, burning 0.5 units/s at cruise
        maneuver: 5 // 12 deg/s and 100 m/s^2
        durable: 5 // 100 hp on 100 units of fuel
        compute: 6
        sensor: 5 // a 60 km radar
        stealth: 5
    }

    abilities: ["guided", "kinetic", "flare"]
}
