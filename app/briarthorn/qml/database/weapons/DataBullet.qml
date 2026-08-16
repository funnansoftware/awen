import QtQuick
import ".."

// The cannon round: a dumb tracer slug, the fastest and shortest-lived thing
// in the sky — four seconds of flight prices a 10 km envelope, so the gun is
// a knife-fight weapon for the ranges where a missile cannot make its turn.
// One round hits light; the gatling wins by putting a stream of them there.
DataWeapon {
    id: root

    classification: Classification.Kind.Bullet
    // A bare line along the flight axis — the polygon degenerates to a
    // stroked dash, so the stream reads as tracer fire, and its marks plot
    // without labels for the same reason.
    outline: [Qt.point(0, -0.5), Qt.point(0, 0.5)]
    label: qsTr("GUN")
    symbolScale: 0.35
    trackLabel: false

    stats: Stats {
        kinetic: 10 // lifted by the muzzle charge below: 2500 m/s, nothing outruns it
        maneuver: 0 // it flies where the nose was pointed
        durable: 0 // too small to frag: a blast passes it by
        stealth: 8
    }

    speedMultiplier: 2.5
    duration: 4

    fuzeRange: 300
    fuzeTime: 0.05
    damage: 4
    blastRadius: 350
}
