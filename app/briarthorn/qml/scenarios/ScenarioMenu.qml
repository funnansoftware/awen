pragma ComponentBehavior: Bound

import QtQml
import awen.entity
import "../database"
import "../model"
import "../systems"

// The main-menu demo: a hands-off, endlessly-looping dogfight in the real
// world, read through the live scope. Ownship orbits the nearest hostile
// under SystemEvade, returns fire off its guided rack and pops flares by
// reflex, while armed waves spawn ahead, bore in and shoot back; a wiped
// wave respawns after a beat, so the menu shows continuous combat with no
// input. The whole show restarts on a clock — briardart rebuilt its demo
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

    // The most rounds one side may hold in the air: the demo reads as a
    // sparring match, not a missile barrage, so each side's engage system
    // stands down until its salvo thins. direct() recounts each tick.
    readonly property int missileCap: 2
    property int ownshipRounds: 0
    property int hostileRounds: 0

    // Seconds the sky has been clear, toward the next wave.
    property real clearTimer: 0

    // Each live bandit's brain, keyed by its entity; spawnWave() appends them
    // to the run and prune() drops them with their craft.
    property var brains: new Map()

    // One wave member's behaviour: chase the player, shoot inside the
    // envelope, pop flares at inbound rounds — the duel bandit's rig.
    // stagger delays the opening shot: the wave spawns inside the envelope
    // with every timer at zero, and the round count the cap reads lags a
    // tick, so unstaggered members all fire together straight through it.
    component BanditBrain: SystemGroup {
        id: brain

        required property Entity entity
        required property real stagger

        SystemPursuit {
            entity: brain.entity
            target: root.ownship
        }

        SystemEngage {
            entity: brain.entity
            target: root.ownship
            timer: brain.stagger
            // Slower than the duel bandit — three shooters share one salvo
            // allowance — and stood down entirely while the side's rounds
            // in the air sit at the cap.
            holdoff: 12
            enabled: root.hostileRounds < root.missileCap
        }

        SystemThreat {
            entity: brain.entity
            world: root.world
        }
    }

    readonly property Component brainFactory: Component {
        BanditBrain {}
    }

    // Wave direction, ahead of everything else in the run: sustain ownship,
    // point its systems at the nearest fighter, keep the wave populated and
    // prune brains whose craft was reaped.
    System {
        function update(dt: real) {
            root.direct(dt);
        }
    }

    SystemEvade {
        id: evade
        entity: root.ownship
    }

    SystemEngage {
        id: engage
        entity: root.ownship
        target: null
        holdoff: 6
        enabled: root.ownshipRounds < root.missileCap
    }

    SystemThreat {
        entity: root.ownship
        world: root.world
    }

    function direct(dt: real) {
        root.showTimer += dt;
        if (root.showTimer >= root.showLength) {
            root.restart();
            return;
        }
        root.sustain();
        root.prune();
        root.countRounds();
        const foes = root.foes();
        if (foes.length === 0) {
            evade.target = null;
            engage.target = null;
            root.clearTimer += dt;
            if (root.clearTimer >= root.respawnDelay) {
                root.clearTimer = 0;
                root.spawnWave();
            }
            return;
        }
        root.clearTimer = 0;
        const threat = root.nearest(foes);
        evade.target = threat;
        engage.target = threat;
    }

    // The demo must never end: hull and tank stay topped and the racks
    // reload, so blasts still land and flares still pop but nothing runs dry.
    function sustain() {
        root.ownship.health = root.ownship.maxHealth;
        root.ownship.fuel = root.ownship.maxFuel;
        const slots = root.ownship.abilities;
        for (let i = 0; i < slots.length; ++i) {
            if (slots[i].def && slots[i].def.charges > 0)
                slots[i].charges = slots[i].def.charges;
        }
    }

    // Tallies each side's rounds in the air for the engage gates above.
    function countRounds() {
        let own = 0;
        let hostile = 0;
        for (let i = 0; i < root.world.entities.length; ++i) {
            const entity = root.world.entities[i];
            if (entity.weapon === null)
                continue;
            if (entity.side === Side.Kind.Hostile)
                ++hostile;
            else
                ++own;
        }
        root.ownshipRounds = own;
        root.hostileRounds = hostile;
    }

    // The living wave members: hostile fighters, not their in-flight rounds.
    function foes(): var {
        return root.world.entities.filter(e => e.side === Side.Kind.Hostile && e.weapon === null && e.classification === Classification.Kind.AircraftFighter);
    }

    function nearest(foes: var): Entity {
        let best = foes[0];
        let bestDistance = root.distanceTo(best);
        for (let i = 1; i < foes.length; ++i) {
            const d = root.distanceTo(foes[i]);
            if (d < bestDistance) {
                best = foes[i];
                bestDistance = d;
            }
        }
        return best;
    }

    function distanceTo(foe: Entity): real {
        return Math.hypot(foe.posX - root.ownship.posX, foe.posY - root.ownship.posY);
    }

    // Spawns a fresh wave fanned out ahead of ownship's nose, each member
    // rated down like the duel bandit and flown by its own appended brain.
    function spawnWave() {
        const heading = root.ownship.heading;
        const aheadRad = heading * Math.PI / 180;
        const acrossRad = (heading + 90) * Math.PI / 180;
        for (let i = 0; i < root.waveSize; ++i) {
            const lateral = (i - (root.waveSize - 1) / 2) * root.spawnSpread;
            const bandit = root.world.spawn("FOE", Classification.Kind.AircraftFighter, {
                side: Side.Kind.Hostile,
                posX: root.ownship.posX + Math.sin(aheadRad) * root.spawnAhead + Math.sin(acrossRad) * lateral,
                posY: root.ownship.posY - Math.cos(aheadRad) * root.spawnAhead - Math.cos(acrossRad) * lateral,
                heading: (heading + 180) % 360,
                speed: 320,
                kinetic: 4.5, // 450 m/s against the demo craft's 500
                maneuver: 4 // 9.6 deg/s against its 12
            });
            const brain = root.brainFactory.createObject(root, {
                entity: bandit,
                stagger: i * 5
            });
            root.brains.set(bandit, brain);
            root.systems.push(brain);
        }
    }

    // Brains whose bandit has been reaped leave the run with their craft.
    function prune() {
        for (const [bandit, brain] of root.brains) {
            if (!root.world.entities.includes(bandit)) {
                root.systems = root.systems.filter(s => s !== brain);
                root.brains.delete(bandit);
                brain.destroy();
            }
        }
    }

    // Ends the show: unhooks ownship's demo targets and drops every brain —
    // the world purge on leaving the menu despawns the bandits themselves.
    function reset() {
        evade.target = null;
        engage.target = null;
        root.clearTimer = 0;
        root.showTimer = 0;
        for (const brain of root.brains.values()) {
            root.systems = root.systems.filter(s => s !== brain);
            brain.destroy();
        }
        root.brains.clear();
    }

    // Reopens the show from the top: sweep everything but ownship out of the
    // world, seat ownship back at the origin and let the wave clock spawn the
    // next engagement — in menu mode every other entity is demo-spawned, so
    // the sweep owns exactly what the demo made.
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
        root.reset();
    }
}
