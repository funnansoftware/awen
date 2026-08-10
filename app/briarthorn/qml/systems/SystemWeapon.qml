import QtQml
import awen.entity
import "../database"
import "../model"

// The weapon engine, ported from briardart's SystemWeapon: consumes raised
// launch intents into missile entities, runs the guided seeker, trips the
// proximity fuze, detonates — flat damage inside the blast radius — and
// reaps spent rounds and killed entities. Runs after SystemMovement so fuze
// checks see fresh poses; seeker steer lands next tick.
System {
    id: root

    // The world this engine spawns into and reaps from.
    required property World world

    // Entities never despawned on zero health (the player's craft).
    property list<Entity> invulnerable

    // Blasts in progress, for the detonation animation.
    property list<Detonation> detonations

    // Seconds a recorded blast lives on screen.
    property real detonationLife: 0.7

    // Bearing error, in degrees, at which a seeker steers full deflection.
    readonly property real cutAngle: 30

    readonly property Component weaponFactory: Component {
        Weapon {}
    }

    readonly property Component detonationFactory: Component {
        Detonation {}
    }

    function update(dt: real) {
        const spent = [];
        const roster = root.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            if (roster[i].weapon !== null)
                root.advance(roster[i], dt, spent);
        }
        root.survey();
        root.consumeLaunches();
        root.reap(spent);
        root.ageDetonations(dt);
    }

    // The shot picture, published before anything launches: for every guided
    // launch slot in the world, the return it would take right now and —
    // where it has none — whether the radar is holding one anyway, out beyond
    // what the round could fly to. A launcher that designates (the player,
    // the demo's director) locks its designated contact or nothing; every
    // other launcher keeps the automatic pick. The rack's readout, the
    // scope's envelope and the launch below all read this one answer, so what
    // the pilot is shown is exactly what the trigger does.
    function survey() {
        for (let i = 0; i < root.world.entities.length; ++i) {
            const launcher = root.world.entities[i];
            const chosen = launcher.selectsTarget ? root.designated(launcher) : null;
            for (let j = 0; j < launcher.abilities.length; ++j) {
                const slot = launcher.abilities[j];
                if (!slot.guided)
                    continue;
                let lock = null;
                let distant = false;
                if (launcher.selectsTarget) {
                    // The designation is judged by the same gates the auto
                    // pick ranks over, against the one contact the pilot
                    // named — and "too far for the round" keeps its own
                    // answer, judged at the radar's own reach.
                    if (chosen !== null && root.takeable(launcher, launcher, launcher.side, chosen, slot.reach))
                        lock = chosen;
                    distant = lock === null && chosen !== null && root.takeable(launcher, launcher, launcher.side, chosen, launcher.detectionRange);
                } else {
                    lock = root.bestReturn(launcher, launcher, launcher.side, slot.reach);
                    // Nothing to take inside the envelope, but something out
                    // past it: "close the range" and "point at something" are
                    // different instructions, so the rack gets to tell them
                    // apart.
                    distant = lock === null && root.bestReturn(launcher, launcher, launcher.side, launcher.detectionRange) !== null;
                }
                // Written only where it changes: a lock repinned in place
                // every tick flickers every binding on it, and restarts the
                // animations gated by them — the same care SystemThreat's
                // mark pass takes.
                if (slot.lock !== lock)
                    slot.lock = lock;
                if (slot.distant !== distant)
                    slot.distant = distant;
                const undesignated = launcher.selectsTarget && launcher.targetContact === "";
                if (slot.undesignated !== undesignated)
                    slot.undesignated = undesignated;
            }
        }
    }

    // The world entity a launcher's designation names, or null. Selection is
    // of a track, so the id resolves against the live world each tick and a
    // spent contact simply stops resolving — no stale lock can publish.
    function designated(launcher: Entity): Entity {
        if (launcher.targetContact === "")
            return null;
        for (let i = 0; i < root.world.entities.length; ++i) {
            if (root.world.entities[i].callsign === launcher.targetContact)
                return root.world.entities[i];
        }
        return null;
    }

    // One round's tick: seek, trip the fuze on a near non-owning entity (or
    // on flight-time running out), and detonate once the fuze delay elapses.
    function advance(missile: Entity, dt: real, spent: var) {
        const w = missile.weapon;
        w.elapsed += dt;
        if (w.state === Weapon.State.Flying) {
            if (w.def.guided)
                root.seek(missile);
            const near = w.def.guided ? w.target : root.nearestNonOwning(missile, w.def.fuzeRange);
            const tripped = near !== null && near.health > 0 && Geo.distance(missile, near) <= w.def.fuzeRange;
            if (tripped || w.elapsed >= w.def.duration) {
                w.state = Weapon.State.Fuzing;
                w.fuzeTarget = tripped ? near : null;
                w.fuzeElapsed = 0;
                missile.commandedSteer = 0;
            }
        } else {
            w.fuzeElapsed += dt;
            if (w.fuzeElapsed >= w.def.fuzeTime) {
                root.detonate(missile);
                spent.push(missile);
            }
        }
    }

    // The semi-active seeker: re-homes every tick on the loudest (lowest
    // stealth) opposed return the owner's radar illuminates, inside
    // seekerRange, and on the nearest of the returns that are equally loud —
    // which is what a flare exploits, wearing its deployer's signature so the
    // round takes whichever of the two it is closer to. No return leaves the
    // round flying straight; a destroyed owner drops the illumination gate
    // (plain homing).
    function seek(missile: Entity) {
        const w = missile.weapon;
        const best = root.bestReturn(missile, missile.owner, missile.side, w.def.seekerRange);
        w.target = best;
        if (best === null) {
            missile.commandedSteer = 0;
            return;
        }
        const error = Geo.wrap180(Geo.bearing(missile, best) - missile.heading);
        missile.commandedSteer = Math.max(-1, Math.min(1, error / root.cutAngle));
    }

    // Consumes launches: a slot fires on a raised intent or on a shot held
    // armed, and only where the survey above says every check passes — a
    // guided round with nothing to lock keeps its charge and stays armed
    // instead, waiting for the pilot to fix what the scope is showing them.
    // One arming is one round, so a launch stands the slot back down. The
    // spawned missile takes its whole flight envelope from its database row
    // and inherits the launcher's side.
    function consumeLaunches() {
        const roster = root.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            const launcher = roster[i];
            for (let j = 0; j < launcher.abilities.length; ++j) {
                const slot = launcher.abilities[j];
                if (!(slot.def instanceof AbilityLaunch))
                    continue;
                const row = slot.round;
                if (row === null) {
                    // A launch naming a kind the database does not carry can
                    // never fire; it must not sit armed forever pretending it
                    // might.
                    slot.pending = false;
                    slot.armed = false;
                    continue;
                }
                const raised = slot.pending || slot.armed;
                slot.pending = false;
                if (!raised)
                    continue;
                if (!slot.valid) {
                    // The press was judged against the survey of the tick
                    // before this one, and the shot can go stale in between.
                    // It is held armed rather than dropped: a press must never
                    // be spent on nothing, which is the whole complaint the
                    // arming state answers.
                    slot.armed = true;
                    continue;
                }
                slot.armed = false;
                const target = row.guided ? slot.lock : null;
                const missile = root.world.spawn("MSL", row.classification, {
                    side: launcher.side,
                    owner: launcher,
                    posX: launcher.posX,
                    posY: launcher.posY,
                    // Every round leaves the rail down the launcher's nose; a
                    // guided one then curves onto its lock through the seeker,
                    // held to the turn rate its maneuver rating buys.
                    heading: launcher.heading,
                    // The motor lifts the round past the airframe ceiling and
                    // it leaves the rail already there, rather than
                    // accelerating up to it — an unguided slug has no agility
                    // to do that with.
                    speedBoost: row.speedMultiplier,
                    speed: row.speed,
                    commandedThrottle: 1
                });
                missile.weapon = root.weaponFactory.createObject(missile, {
                    def: row,
                    target: target
                });
                slot.charges = slot.charges > 0 ? slot.charges - 1 : slot.charges;
                slot.cooldownRemaining = slot.def.cooldown;
            }
        }
    }

    // The blast: record the detonation for the view, then flat damage to
    // every entity inside blastRadius — sparing the round itself and its
    // owner, briardart's self-frag protection.
    function detonate(missile: Entity) {
        const w = missile.weapon;
        root.detonations = [...root.detonations, root.detonationFactory.createObject(root, {
            worldX: missile.posX,
            worldY: missile.posY,
            blastRadius: w.def.blastRadius,
            life: root.detonationLife,
            maxLife: root.detonationLife
        })];
        for (let i = 0; i < root.world.entities.length; ++i) {
            const struck = root.world.entities[i];
            if (struck === missile || struck === missile.owner)
                continue;
            if (Geo.distance(missile, struck) <= w.def.blastRadius)
                struck.health = Math.max(0, struck.health - w.def.damage);
        }
    }

    // Despawns detonated rounds and anything killed this tick; entities
    // never given hull (maxHealth 0) and the invulnerable list are exempt.
    function reap(spent: var) {
        const roster = root.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            const entity = roster[i];
            if (spent.includes(entity))
                root.world.despawn(entity);
            else if (entity.maxHealth > 0 && entity.health <= 0 && !root.invulnerable.includes(entity))
                root.world.despawn(entity);
        }
    }

    // Puts every blast out. They burn down on simulation time, so the one lit
    // on the frame a duel is decided never runs down at all — the sim stops
    // with it — and would otherwise be handed to the next game to finish
    // burning at a world position nothing is standing at any more.
    function reset() {
        const lit = root.detonations.slice();
        root.detonations = [];
        for (let i = 0; i < lit.length; ++i)
            lit[i].destroy();
    }

    function ageDetonations(dt: real) {
        let expired = false;
        for (let i = 0; i < root.detonations.length; ++i) {
            root.detonations[i].life -= dt;
            if (root.detonations[i].life <= 0)
                expired = true;
        }
        if (expired) {
            const dead = root.detonations.filter(d => d.life <= 0);
            root.detonations = root.detonations.filter(d => d.life > 0);
            dead.forEach(d => d.destroy());
        }
    }

    // Whether one return passes every gate a seeker needs — live, opposed,
    // inside range, illuminated by the radar cone and in line of sight. The
    // one definition the automatic pick ranks over and a designation is
    // judged by, so the two policies can never disagree about what is
    // takeable.
    function takeable(at: Entity, illuminator: Entity, side: int, contact: Entity, range: real): bool {
        if (contact === at || contact === illuminator || contact.health <= 0)
            return false;
        if (!root.opposed(side, contact.side))
            return false;
        if (Geo.distance(at, contact) > range || !root.illuminated(illuminator, contact))
            return false;
        // The seeker is a radar receiver too: a return behind a pillar
        // reaches neither it nor the illuminator.
        return Geo.lineOfSight(at, contact, root.world.obstacles);
    }

    // The loudest opposed live return within range of at, gated by the
    // illuminator's radar cone; ties break to the nearest — the tie a craft
    // and its own flare are always in, so range alone decides between them
    // and a pop only works while the deployer flies off the decoy.
    function bestReturn(at: Entity, illuminator: Entity, side: int, range: real): Entity {
        let best = null;
        let bestDist = 0;
        for (let i = 0; i < root.world.entities.length; ++i) {
            const contact = root.world.entities[i];
            if (!root.takeable(at, illuminator, side, contact, range))
                continue;
            const d = Geo.distance(at, contact);
            if (best === null || contact.stealth < best.stealth || (contact.stealth === best.stealth && d < bestDist)) {
                best = contact;
                bestDist = d;
            }
        }
        return best;
    }

    // The nearest live entity the round's owner does not also own — the
    // proximity-fuze trigger set for a kinetic round.
    function nearestNonOwning(missile: Entity, range: real): Entity {
        let best = null;
        let bestDist = range;
        for (let i = 0; i < root.world.entities.length; ++i) {
            const contact = root.world.entities[i];
            if (contact === missile || contact === missile.owner || contact.health <= 0)
                continue;
            if (missile.owner !== null && contact.owner === missile.owner)
                continue;
            const d = Geo.distance(missile, contact);
            if (d <= bestDist) {
                best = contact;
                bestDist = d;
            }
        }
        return best;
    }

    // Whether the illuminator's radar cone paints the contact — inside the
    // cone with a clear line past the arena's pillars; a missing illuminator
    // is lenient, per briardart.
    function illuminated(illuminator: Entity, contact: Entity): bool {
        if (illuminator === null)
            return true;
        const off = Geo.wrap180(Geo.bearing(illuminator, contact) - illuminator.heading);
        return Math.abs(off) <= illuminator.radarFov / 2 && Geo.lineOfSight(illuminator, contact, root.world.obstacles);
    }

    // Whether two sides shoot at each other: ownship and friendly versus
    // hostile; unknowns and neutrals engage no one.
    function opposed(a: int, b: int): bool {
        const friend = s => s === Side.Kind.Ownship || s === Side.Kind.Friendly;
        return (friend(a) && b === Side.Kind.Hostile) || (a === Side.Kind.Hostile && friend(b));
    }
}
