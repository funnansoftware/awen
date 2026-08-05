import QtQml
import awen.entity
import "../database"
import "../model"

// The main-menu demo: a hands-off, endlessly-looping dogfight in the real
// world, read through the live scope. Everything flies on entity aspects the
// shared systems process — ownship orbits and returns fire through the
// targets the director points, and each wave slot spawns flying its own
// temperament against the player — so the scenario owns one director and no
// systems. The whole show restarts on a clock: briardart rebuilt its demo
// session on every menu entry, and an unbounded run would carry ownship
// arbitrarily far from the origin. Ports briardart's MenuDemoController.
Scenario {
    id: root

    // The demonstrating craft (the game store owns it) and the world the
    // waves spawn into.
    required property Entity ownship
    required property World world

    // Wave shape: how many fighters spawn, how far ahead of ownship's nose,
    // the lateral gap fanning them out, and the pause after a wipe.
    readonly property int waveSize: 3
    readonly property real spawnAhead: 26000
    readonly property real spawnSpread: 9000
    readonly property real respawnDelay: 1.4

    // Seconds one showing runs before the demo sweeps itself clean and opens
    // again from the origin, and the run clock counting toward that. Short
    // enough that a fight decaying into a chase never lingers, and no showing
    // outlives the wave's racks.
    readonly property real showLength: 30
    property real showTimer: 0

    // The most rounds ownship may hold in the air: its half of the sparring
    // match stays paced behind its engageHold flag, while the bandits'
    // trigger discipline belongs to their personalities.
    readonly property int missileCap: 2
    property int ownshipRounds: 0

    // Seconds a bandit's opening shot waits per wave slot, so a fresh wave —
    // spawned inside the envelope with every timer at zero — never opens as
    // one volley.
    readonly property real stagger: 5

    // One temperament per wave slot, so a single showing demonstrates the
    // range: the leader presses in, the second cycles its firing band, the
    // third snipes from distance and bails under fire.
    readonly property list<string> temperaments: [Names.personality.aggressive, Names.personality.tactical, Names.personality.fearful]

    // How the demo craft fights: launches paced a beat apart.
    readonly property real demoHoldoff: 6

    // Ownship's demo behaviour, armed by restart(): orbit the threat the
    // director points at standoff. Scenario-owned, so it outlives the craft
    // swaps and strips cleanly on reset().
    readonly property ManeuverEvade evade: ManeuverEvade {}


    // Seconds the sky has been clear, toward the next wave.
    property real clearTimer: 0

    // Wave direction, the scenario's one running part: sustain ownship,
    // point its aspects at the nearest fighter, hold each side's shooters at
    // the salvo cap and keep the wave populated.
    System {
        function update(dt: real) {
            root.direct(dt);
        }
    }

    function direct(dt: real) {
        root.showTimer += dt;
        if (root.showTimer >= root.showLength) {
            root.restart();
            return;
        }
        root.sustain();
        root.countRounds();
        const foes = root.foes();
        root.ownship.engageHold = root.ownshipRounds >= root.missileCap;
        if (foes.length === 0) {
            root.evade.target = null;
            root.ownship.engageTarget = null;
            // With no aspect steering it, ownship flies straight and level
            // toward the next engagement.
            root.ownship.commandedSteer = 0;
            root.ownship.commandedThrottle = 1;
            root.clearTimer += dt;
            if (root.clearTimer >= root.respawnDelay) {
                root.clearTimer = 0;
                root.spawnWave();
            }
            return;
        }
        root.clearTimer = 0;
        const threat = root.nearest(foes);
        root.evade.target = threat;
        root.ownship.engageTarget = threat;
    }

    // The demo must never end: the hull stays topped (SystemWeapon must keep
    // running — blasts and reaping are the show — so hits do land) and the
    // racks reload. Fuel needs nothing: burnsFuel is cleared on the craft.
    function sustain() {
        root.ownship.health = root.ownship.maxHealth;
        const slots = root.ownship.abilities;
        for (let i = 0; i < slots.length; ++i) {
            if (slots[i].def && slots[i].def.charges > 0)
                slots[i].charges = slots[i].def.charges;
        }
    }

    // Tallies ownship's rounds in the air for the engageHold gate above.
    function countRounds() {
        let own = 0;
        for (let i = 0; i < root.world.entities.length; ++i) {
            const entity = root.world.entities[i];
            if (entity.weapon !== null && entity.side !== Side.Kind.Hostile)
                ++own;
        }
        root.ownshipRounds = own;
    }

    // The living wave members — the kind spawnWave() makes, so the director
    // sees exactly its own bandits: not their in-flight rounds, and not the
    // flares they pop (hostile-sided, but never fighters).
    function foes(): var {
        return root.world.entities.filter(e => e.side === Side.Kind.Hostile && e.weapon === null && e.classification === Classification.Kind.AircraftFighterLight);
    }

    function nearest(foes: var): Entity {
        let best = foes[0];
        let bestDistance = Geo.distance(root.ownship, best);
        for (let i = 1; i < foes.length; ++i) {
            const d = Geo.distance(root.ownship, foes[i]);
            if (d < bestDistance) {
                best = foes[i];
                bestDistance = d;
            }
        }
        return best;
    }

    // Spawns a fresh wave fanned out ahead of ownship's nose — downrated
    // airframes off the database, each flying its slot's temperament against
    // the player from birth. The personalities own their maneuvers and
    // trigger discipline; the director only points the target and staggers
    // the opening shots.
    function spawnWave() {
        const heading = root.ownship.heading;
        for (let i = 0; i < root.waveSize; ++i) {
            const lateral = (i - (root.waveSize - 1) / 2) * root.spawnSpread;
            root.world.spawn("FOE", Classification.Kind.AircraftFighterLight, {
                side: Side.Kind.Hostile,
                posX: root.ownship.posX + Geo.offsetX(heading, root.spawnAhead) + Geo.offsetX(Geo.perpendicularRight(heading), lateral),
                posY: root.ownship.posY + Geo.offsetY(heading, root.spawnAhead) + Geo.offsetY(Geo.perpendicularRight(heading), lateral),
                heading: Geo.reciprocal(heading),
                speed: 320,
                personality: root.temperaments[i % root.temperaments.length],
                engageTarget: root.ownship,
                // The base pace for stances that keep the spawn setting;
                // firing stances repace themselves.
                engageHoldoff: 12,
                engageTimer: i * root.stagger,
                threatReflex: true
            });
        }
    }

    // Ends the show: strips the demo aspects off the player's craft — the
    // wave bandits despawn with the world purge on leaving the menu.
    function reset() {
        root.evade.target = null;
        root.ownship.maneuvers = [];
        root.ownship.engageTarget = null;
        root.ownship.engageHold = false;
        root.clearTimer = 0;
        root.showTimer = 0;
    }

    // Reopens the show from the top: sweep everything but ownship out of the
    // world, seat ownship back at the origin armed for the demo — reflexive
    // flares, a paced trigger, no fuel burn — and let the wave clock spawn
    // the next engagement. In menu mode every other entity is demo-spawned,
    // so the sweep owns exactly what the demo made.
    function restart() {
        const roster = root.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            if (roster[i] !== root.ownship)
                root.world.despawn(roster[i]);
        }
        root.ownship.posX = 0;
        root.ownship.posY = 0;
        root.ownship.heading = 0;
        root.ownship.speed = 0;
        root.ownship.burnsFuel = false;
        root.ownship.threatReflex = true;
        root.ownship.engageHoldoff = root.demoHoldoff;
        root.ownship.engageTimer = 0;
        root.reset();
        // Re-armed after the strip: the demo craft flies the scenario's own
        // orbit maneuver, pointed by the director as the fight moves.
        root.ownship.maneuvers = [root.evade];
    }
}
