import "../database"
import "../model"
import "../systems"

// The 1v1 duel: one hostile fighter boring in from the north, spawned just
// past sensor range so it opens as an Unknown contact. The bandit shoots
// back — guided rounds inside its engage envelope — and pops flares when a
// missile homes in on it.
Scenario {
    id: root

    // The player's craft, for the bandit to pursue; the game store owns it.
    required property Entity ownship

    // The world the bandit's defensive scan reads.
    required property World world

    // The same fighter airframe the player flies, rated down a little so the
    // duel is winnable, and carrying a lighter loadout than the stock rack.
    readonly property Entity bandit: Entity {
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Hostile
        posY: -65000
        heading: 180
        kinetic: 4.5 // 450 m/s against the player's 500
        maneuver: 4 // 9.6 deg/s against the player's 12

        // Guided rounds and a half-size flare pod; no kinetic rack at all.
        abilities: [
            AbilitySlot {
                def: Abilities.defFor("guided")
            },
            AbilitySlot {
                def: Abilities.defFor("flare")
                charges: 6
            }
        ]
    }

    entities: [root.bandit]

    SystemPursuit {
        entity: root.bandit
        target: root.ownship
    }

    SystemEngage {
        entity: root.bandit
        target: root.ownship
    }

    SystemThreat {
        entity: root.bandit
        world: root.world
    }
}
