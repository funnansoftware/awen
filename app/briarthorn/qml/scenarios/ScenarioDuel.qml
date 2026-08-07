// The bandit's declaration reaches the file root's ownship; bound component
// behaviour is what makes that resolve statically.
pragma ComponentBehavior: Bound

import QtQml
import "../database"
import "../model"

// The 1v1 duel: one hostile fighter closing from the north, spawned just
// past sensor range so it opens as an Unknown contact. Pure initial
// conditions — the bandit's declaration carries its behaviour aspects
// (press to fire, crank behind the round in flight, beam inbounds, flare at
// them) and the shared systems do the rest; this scenario loads nothing of
// its own.
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
        // Seated a shade east of true north: the closing line to the merge
        // then passes the north pillar with kilometres to spare, where the
        // axis itself would fly the pursuit straight into it.
        posX: 10000
        posY: -64000
        heading: 180
        personality: Names.personality.duelist
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

    // The arena: four large pillars boxing the fight at 60 km on the
    // cardinals, a picket of smaller ones every 45 degrees at 120 km, and
    // four more on the intercardinals at 30 km — off the cardinal axes, so
    // the opening lane from the north stays flyable. Static terrain, so
    // reset() never touches it.
    readonly property Component pillarFactory: Component {
        Obstacle {}
    }

    obstacles: [...root.pillarRing(4, 0, 60000, 6000), ...root.pillarRing(8, 0, 120000, 3000), ...root.pillarRing(4, 45, 30000, 3000)]

    // count pillars of one radius, evenly spaced around the origin at range,
    // the first seated at startBearing.
    function pillarRing(count: int, startBearing: real, range: real, radius: real): list<Obstacle> {
        const ring = [];
        for (let i = 0; i < count; ++i) {
            const bearing = startBearing + i * 360 / count;
            ring.push(root.pillarFactory.createObject(root, {
                posX: Geo.offsetX(bearing, range),
                posY: Geo.offsetY(bearing, range),
                radius: radius
            }));
        }
        return ring;
    }

    // Replaces the bandit with a factory-fresh one — QML's constructor — so a
    // duel entered from the menu always opens the same fight, with nothing to
    // restore field by field. The caller re-enrolls the scenario's entities.
    function reset() {
        const spent = root.bandit;
        root.bandit = root.banditFactory.createObject(root) as Entity;
        spent.destroy();
    }
}
