import ".."

// The downrated fighter hostiles fly — the stock airframe with the edge taken
// off its engine and its agility, and no kinetic rack, so the player always
// holds the performance advantage. The duel bandit and the menu demo's waves
// both spawn this kind.
DataAircraftFighter {
    id: root

    classification: Classification.Kind.AircraftFighterLight

    stats: Stats {
        kinetic: 2.5 // 250 m/s against the stock fighter's 300
        maneuver: 4 // 9.6 deg/s against its 12
        durable: 5
        compute: 6
        sensor: 5
        stealth: 5
    }

    abilities: ["guided", "flare"]
}
