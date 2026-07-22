import "../model"
import "../systems"

// The 1v1 duel: one hostile fighter boring in from the north, spawned just
// past sensor range so it opens as an Unknown contact.
Scenario {
    id: scenario

    // The player's craft, for the bandit to pursue; the game store owns it.
    required property Entity ownship

    readonly property Entity bandit: Entity {
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Hostile
        posY: -65000
        heading: 180
        radarFov: 120
        kinetic: 450
        maneuver: 9
        durable: 5
        compute: 6
        sensor: 60000
        stealth: 5
    }

    entities: [scenario.bandit]

    SystemPursuit {
        entity: scenario.bandit
        target: scenario.ownship
    }
}
