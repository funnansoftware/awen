import QtQuick
import ".."

// The anti-air site: a dug-in missile battery whose radar dish is the
// entity's own heading — SystemSentry sweeps it and locks what the volume
// catches, and the guided rack fires through the same engage machinery a
// fighter's does. kinetic 0 pins it in place and zeroes its fuel burn while
// the maneuver rating still prices the dish's turn.
DataEntity {
    id: root

    classification: Classification.Kind.SiteAntiAir
    // A squat ground pentagon with a nose: asymmetric on purpose, so the
    // mark's rotation reads as the sweep on the scope.
    outline: [Qt.point(0, -0.5), Qt.point(0.38, -0.05), Qt.point(0.24, 0.45), Qt.point(-0.24, 0.45), Qt.point(-0.38, -0.05)]
    label: qsTr("SAM")
    symbolScale: 0.9
    hullGauge: true

    // The wedge the dish paints. Narrow, or the sweep stops meaning anything:
    // the volume is a searchlight, not a floodlight.
    radarFov: 40

    stats: Stats {
        kinetic: 0
        maneuver: 6
        durable: 5
        compute: 6
        // The search volume: 42 km, and the engagement lobe GameRules prices
        // off it, 27 km. This is the one knob that sizes a battery, and what
        // caps it is how thickly they are seeded rather than what one set
        // could do: a lobe wider than half the spacing between neighbours
        // meets the next one and leaves no flyable ground between them. The
        // duel stands four of them 70 km apart, which puts that ceiling at a
        // rating of 4.5 — reach here is bought by standing further out, and
        // moving them back in again costs it straight back.
        sensor: 3.5
        // Exactly a fighter's loudness, so a player round with both the site
        // and the bandit illuminated takes whichever is nearer rather than
        // systematically deserting one shot for the other.
        stealth: 5
    }

    abilities: ["guided"]
}
