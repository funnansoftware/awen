import QtQml
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

    // The downrated airframe, so the duel is winnable, with its rack's flare
    // pod halved on top — a full pod outlasts the player's patience.
    component DuelBandit: Entity {
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighterLight
        side: Side.Kind.Hostile
        posY: -65000
        heading: 180

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

    // The live bandit. reset() owns the swap.
    property Entity bandit: DuelBandit {}

    readonly property Component banditFactory: Component {
        DuelBandit {}
    }

    entities: [root.bandit]

    // Replaces the bandit with a factory-fresh one — QML's constructor — so a
    // duel entered from the menu always opens the same fight, with nothing to
    // restore field by field. The caller re-enrolls the scenario's entities.
    function reset() {
        const spent = root.bandit;
        root.bandit = root.banditFactory.createObject(root) as Entity;
        spent.destroy();
    }

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

    // The player's tank drains only while a duel is on: the menu demo simply
    // carries no fuel system, so it needs no top-up either.
    SystemFuel {
        entity: root.ownship
    }
}
