import QtQuick
import ".."

// The guided round: homes on the loudest return its launcher illuminates. It
// outruns the kinetic slug and reaches far further, but hits softer.
DataWeapon {
    classification: Classification.Kind.MissileGuided
    outline: [Qt.point(0, -0.5), Qt.point(0.15, 0.5), Qt.point(-0.15, 0.5)]
    label: qsTr("MSL")
    symbolScale: 0.55

    stats: Stats {
        kinetic: 9 // 900 m/s, doubled by the motor below
        maneuver: 10 // 24 deg/s: the most agile thing in the sky
        durable: 1 // 20 hp
        compute: 6 // a 90 km seeker
        sensor: 6
        stealth: 8 // a small, quiet return
    }

    // A burning motor screams past the airframe ceiling at 1800 m/s, and over
    // 24 s of flight that is ~43 km of reach.
    speedMultiplier: 2
    duration: 24
    guided: true

    fuzeRange: 500
    fuzeTime: 0.3
    damage: 55
    blastRadius: 900
}
