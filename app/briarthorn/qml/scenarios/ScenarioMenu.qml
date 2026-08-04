import awen.entity
import "../database"
import "../model"

// The main-menu demo: a hands-off, endlessly-looping dogfight in the real
// world, read through the live scope. Everything flies on entity aspects the
// shared systems process — ownship orbits and returns fire through the
// targets the director points, waves spawn already declaring pursuit, trigger
// discipline and flare reflex — so the scenario owns one director and no
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

    // The most rounds one side may hold in the air: the demo reads as a
    // sparring match, not a missile barrage, so each side's shooters stand
    // down behind their engageHold flags until their salvo thins.
    readonly property int missileCap: 2
    property int ownshipRounds: 0
    property int hostileRounds: 0

    // Seconds a bandit's opening shot waits per wave slot, so a fresh wave —
    // spawned inside the envelope with every timer at zero — never fires as
    // one volley straight through the lagging round count.
    readonly property real stagger: 5

    // How the demo craft fights: launches paced a beat apart.
    readonly property real demoHoldoff: 6

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
        const hostileHold = root.hostileRounds >= root.missileCap;
        for (let i = 0; i < foes.length; ++i)
            foes[i].engageHold = hostileHold;
        if (foes.length === 0) {
            root.ownship.evadeTarget = null;
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
        root.ownship.evadeTarget = threat;
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

    // Tallies each side's rounds in the air for the engageHold gates above.
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
    // airframes off the database, each declaring its whole behaviour at
    // birth: chase the player, shoot on a slow cadence from a staggered
    // start, flare at inbound rounds.
    function spawnWave() {
        const heading = root.ownship.heading;
        for (let i = 0; i < root.waveSize; ++i) {
            const lateral = (i - (root.waveSize - 1) / 2) * root.spawnSpread;
            root.world.spawn("FOE", Classification.Kind.AircraftFighterLight, {
                side: Side.Kind.Hostile,
                posX: root.ownship.posX + Geo.offsetX(heading, root.spawnAhead) + Geo.offsetX(heading + 90, lateral),
                posY: root.ownship.posY + Geo.offsetY(heading, root.spawnAhead) + Geo.offsetY(heading + 90, lateral),
                heading: (heading + 180) % 360,
                speed: 320,
                pursuitTarget: root.ownship,
                engageTarget: root.ownship,
                // Slower than the duel bandit: three shooters share one
                // salvo allowance.
                engageHoldoff: 12,
                engageTimer: i * root.stagger,
                threatReflex: true
            });
        }
    }

    // Ends the show: strips the demo aspects off the player's craft — the
    // wave bandits despawn with the world purge on leaving the menu.
    function reset() {
        root.ownship.evadeTarget = null;
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
    }
}
