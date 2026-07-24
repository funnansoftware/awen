import "../model"
import "../systems"

// The 1v1 duel: one hostile fighter boring in from the north, spawned just
// past sensor range so it opens as an Unknown contact. The bandit shoots
// back — guided rounds inside its engage envelope — and pops flares when a
// missile homes in on it.
Scenario {
    id: scenario

    // The player's craft, for the bandit to pursue; the game store owns it.
    required property Entity ownship

    // The world the bandit's defensive scan reads.
    required property World world

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
        maxHealth: durable * 20
        health: maxHealth

        abilities: [
            AbilitySlot {
                def: Abilities.launchGuided
            },
            AbilitySlot {
                def: Abilities.flare
                charges: 6
            }
        ]
    }

    entities: [scenario.bandit]

    SystemPursuit {
        entity: scenario.bandit
        target: scenario.ownship
    }

    SystemEngage {
        entity: scenario.bandit
        target: scenario.ownship
    }

    SystemThreat {
        entity: scenario.bandit
        world: scenario.world
    }
}
