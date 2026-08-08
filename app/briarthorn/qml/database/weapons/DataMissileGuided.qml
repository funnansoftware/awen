import QtQuick
import ".."

// The guided round: homes on the loudest return its launcher illuminates. It
// flies slower than the kinetic slug and hits softer, buying that back with a
// seeker that steers it onto a target the dumb slug could never touch.
DataWeapon {
    id: root

    classification: Classification.Kind.MissileGuided
    // A finned dart — the steering surfaces tell it from the kinetic slug's
    // plain triangle on the scope.
    outline: [Qt.point(0, -0.5), Qt.point(0.12, 0.1), Qt.point(0.32, 0.5), Qt.point(0, 0.32), Qt.point(-0.32, 0.5), Qt.point(-0.12, 0.1)]
    label: qsTr("MSL")
    symbolScale: 0.55

    stats: Stats {
        kinetic: 8
        maneuver: 6
        durable: 1
        compute: 6
        sensor: 6
        stealth: 8
    }

    // No motor boost: it cruises at the airframe speed its kinetic rating
    // buys, and over 24 s of flight that is ~19 km of reach.
    speedMultiplier: 1
    duration: 64
    guided: true

    fuzeRange: 1000
    fuzeTime: 0.3
    damage: 55
    blastRadius: 900
}
