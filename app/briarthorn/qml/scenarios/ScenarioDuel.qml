// The bandit's declaration reaches the file root's ownship; bound component
// behaviour is what makes that resolve statically.
pragma ComponentBehavior: Bound

import QtQml
import "../database"
import "../model"

// The 1v1 duel: one hostile fighter boring in from the north, spawned just
// past sensor range so it opens as an Unknown contact. Pure initial
// conditions — the bandit's declaration carries its behaviour aspects
// (pursue the player, shoot inside the envelope, flare at inbound rounds)
// and the shared systems do the rest; this scenario loads nothing of its own.
Scenario {
    id: root

    // The player's craft, for the bandit to pursue; the game store owns it.
    required property Entity ownship

    // The downrated airframe, so the duel is winnable, with its rack's flare
    // pod halved on top — a full pod outlasts the player's patience. The
    // scenario points the target; the personality decides how to fight it,
    // so a dry bandit breaks off rather than pursuing forever.
    component DuelBandit: Entity {
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighterLight
        side: Side.Kind.Hostile
        posY: -65000
        heading: 180
        personality: "aggressive"
        engageTarget: root.ownship
        threatReflex: true

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
}
