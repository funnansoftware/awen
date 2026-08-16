import ".."

// The downrated fighter hostiles fly — the stock airframe with the edge taken
// off its engine and its agility, and no kinetic rack, so the player always
// holds the performance advantage. The duel bandit and the menu demo's waves
// both spawn this kind.
DataAircraftFighter {
    id: root

    classification: Classification.Kind.AircraftFighterLight
    radarFov: 90

    stats: Stats {
        kinetic: 4.5
        maneuver: 6
        durable: 5
        compute: 6
        sensor: 6
        stealth: 5
    }

    abilities: ["guided", "gun", "flare"]
}
