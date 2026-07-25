import QtQuick
import ".."

// The kinetic slug: unguided, so the pilot buys the aiming problem along with
// it, but a wide fuze and a big warhead make up for the dumb seeker.
DataWeapon {
    classification: Classification.Kind.MissileKinetic
    outline: [Qt.point(0, -0.5), Qt.point(0.15, 0.5), Qt.point(-0.15, 0.5)]
    label: qsTr("MSL")
    symbolScale: 0.55

    stats: Stats {
        kinetic: 10 // 1000 m/s off the rail
        maneuver: 0 // no steering at all: it flies where it was pointed
        durable: 1 // 20 hp
        stealth: 8
    }

    duration: 18

    fuzeRange: 1200
    fuzeTime: 0.3
    damage: 80
    blastRadius: 2500
}
