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
// them and run off the flare once one bites) and the shared systems do the
// rest; this scenario loads nothing of its own.
Scenario {
    id: root

    // The player's craft, for the bandit to pursue; the game store owns it.
    required property Entity ownship

    // Where the player opens the duel: due south of the merge, mirroring the
    // bandit's seat, so the two start the same distance off the origin. The
    // 85 km split seats each craft 13 km beyond the other's 72 km radar, so
    // the contact opens Unknown and resolves about twenty seconds in rather
    // than after two minutes of empty sky.
    //
    // On the meridian, not offset off it: with batteries on the diagonals the
    // safe ground is the cardinal lanes between them, and opening in one is
    // what makes the arena's shape teachable from the first second.
    readonly property real ownshipPosX: 0
    readonly property real ownshipPosY: 42500
    readonly property real ownshipHeading: 0

    // The downrated airframe, so the duel is winnable, with its rack's flare
    // pod halved on top — a full pod outlasts the player's patience. The
    // scenario points the target; the personality decides how to fight it,
    // so a dry bandit breaks off rather than pursuing forever.
    component DuelBandit: Entity {
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighterLight
        side: Side.Kind.Hostile
        // Seated on the meridian, mirroring the player. The walls sit on it
        // too, 17.5 km past each opening mark, so the closing lines run clear
        // of everything and only a craft that keeps running meets one — the
        // bandit gets turned by SystemAvoidance, the player gets TERRAIN,
        // since avoidance skips an entity with no maneuvers. The batteries
        // are the bandit's own, so it flies this lane untroubled by the lobes
        // the player has to stay between.
        posX: root.ownshipPosX
        posY: -root.ownshipPosY
        heading: 180
        personality: Names.personality.duelist
        engageTarget: root.ownship
        threatReflex: true

        abilities: [
            AbilitySlot {
                def: Abilities.defFor("guided")
            },
            AbilitySlot {
                def: Abilities.defFor("gun")
            },
            AbilitySlot {
                def: Abilities.defFor("flare")
                charges: 6
            }
        ]
    }

    // An anti-air battery standing where a pillar stood: a sentry the shared
    // systems run whole — SystemSentry sweeps and locks, SystemEngage fires,
    // and its rounds ride its own illumination, so masking the dish blinds
    // them. Four rounds paced well apart, so a full transit of a lobe eats
    // the whole rack rather than one salvo.
    component DuelSite: Entity {
        classification: Classification.Kind.SiteAntiAir
        side: Side.Kind.Hostile
        sentry: true
        engageHoldoff: 14

        abilities: [
            AbilitySlot {
                def: Abilities.defFor("guided")
                charges: 4
            }
        ]
    }

    // The live bandit and batteries. reset() owns the swaps.
    property Entity bandit: DuelBandit {}
    property list<Entity> sites: root.makeSites()

    readonly property Component banditFactory: Component {
        DuelBandit {}
    }

    readonly property Component siteFactory: Component {
        DuelSite {}
    }

    entities: [root.bandit, ...root.sites]

    // Where the batteries sit: on the four intercardinals, 50 km out. Standing
    // them that far apart — 70 km between neighbours — is what buys the reach,
    // since a lobe may not exceed half the spacing without meeting the next
    // one and leaving the arena with no flyable ground (see DataSiteAntiAir).
    //
    // The shape that falls out is the whole level design. A 22.7 km bubble at
    // the centre where the two craft merge, unwatched by anything; four lobes
    // out on the diagonals; and four lanes on the cardinals between them,
    // 16 km wide, each gated at its far end by one of the 6 km walls. The
    // lanes run inside the searches and outside the engagements, so a dish
    // swings onto a craft flying one and holds it the whole way without a
    // shot — every approach is watched, and only leaving the lane is paid for.
    readonly property list<real> siteBearings: [45, 135, 225, 315]
    readonly property real siteRange: 50000

    // Each battery's screens: three discs ringing it, transparent to its own
    // side and solid to everyone else. They are what makes a battery hard to
    // kill rather than hard to survive — it shoots out through them freely
    // while an attacker can neither see nor shoot through, so a strike has to
    // be flown into one of the three gaps between them. Nine km out and four
    // across leaves each gap about 67 degrees wide: enough to find, not
    // enough to stumble into.
    readonly property int screenCount: 3
    readonly property real screenRange: 9000
    readonly property real screenRadius: 4000

    // The batteries, seated on those bearings and opened each pointed a
    // quarter turn from the last, so the four sweeps never march together.
    function makeSites(): list<Entity> {
        const built = [];
        for (let i = 0; i < root.siteBearings.length; ++i) {
            const bearing = root.siteBearings[i];
            built.push(root.siteFactory.createObject(root, {
                callsign: "SAM " + (i + 1),
                posX: Geo.offsetX(bearing, root.siteRange),
                posY: Geo.offsetY(bearing, root.siteRange),
                heading: i * 90
            }) as Entity);
        }
        return built;
    }

    // The arena's terrain: the four big walls on the cardinals at 60 km, one
    // gating the far end of each lane, plus the screens ringing each battery.
    // Nothing else — the middle of the arena is defended rather than solid,
    // so a lock is broken by leaving the lobe rather than by hiding in it,
    // and the only cover that exists is cover the enemy shoots through.
    // Static, so reset() never touches it.
    readonly property Component pillarFactory: Component {
        Obstacle {}
    }

    obstacles: [...root.pillarRing(4, 0, 60000, 6000), ...root.makeScreens()]

    // The screens, three to a battery. The first faces the arena centre —
    // where an attacker comes from — and the others space out from it, so the
    // gaps a shot has to be lined up through are never on the obvious
    // approach. They are the battery's own, so it neither sees nor flies into
    // them; everything else does.
    function makeScreens(): list<Obstacle> {
        const built = [];
        for (let i = 0; i < root.siteBearings.length; ++i) {
            const seatX = Geo.offsetX(root.siteBearings[i], root.siteRange);
            const seatY = Geo.offsetY(root.siteBearings[i], root.siteRange);
            for (let j = 0; j < root.screenCount; ++j) {
                const around = root.siteBearings[i] + 180 + j * 360 / root.screenCount;
                built.push(root.pillarFactory.createObject(root, {
                    posX: seatX + Geo.offsetX(around, root.screenRange),
                    posY: seatY + Geo.offsetY(around, root.screenRange),
                    radius: root.screenRadius,
                    transparentTo: Side.Kind.Hostile
                }) as Obstacle);
            }
        }
        return built;
    }

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

    // Replaces the bandit and the batteries with factory-fresh ones — QML's
    // constructor — so a duel entered from the menu always opens the same
    // fight, with nothing to restore field by field, and seats the player's
    // craft at its opening mark. Ownship is the store's, rebuilt just before
    // this runs, so its initial conditions are set here rather than declared
    // on a spawn site. The caller re-enrolls the scenario's entities.
    function reset() {
        const spent = [root.bandit, ...root.sites];
        root.bandit = root.banditFactory.createObject(root) as Entity;
        root.sites = root.makeSites();
        for (let i = 0; i < spent.length; ++i)
            spent[i].destroy();

        root.ownship.posX = root.ownshipPosX;
        root.ownship.posY = root.ownshipPosY;
        root.ownship.heading = root.ownshipHeading;
    }
}
