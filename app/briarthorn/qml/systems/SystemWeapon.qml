import QtQml
import awen.entity
import "../model"

// The weapon engine, ported from briardart's SystemWeapon: consumes raised
// launch intents into missile entities, runs the guided seeker, trips the
// proximity fuze, detonates — flat damage inside the blast radius — and
// reaps spent rounds and killed entities. Runs after SystemMovement so fuze
// checks see fresh poses; seeker steer lands next tick.
System {
    id: weapons

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
        const roster = weapons.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            if (roster[i].weapon !== null)
                weapons.advance(roster[i], dt, spent);
        }
        weapons.consumeLaunches();
        weapons.reap(spent);
        weapons.ageDetonations(dt);
    }

    // One round's tick: seek, trip the fuze on a near non-owning entity (or
    // on flight-time running out), and detonate once the fuze delay elapses.
    function advance(missile: Entity, dt: real, spent: var) {
        const w = missile.weapon;
        w.elapsed += dt;
        if (w.state === Weapon.State.Flying) {
            if (w.def.guided)
                weapons.seek(missile);
            const near = w.def.guided ? w.target : weapons.nearestNonOwning(missile, w.def.fuzeRange);
            const tripped = near !== null && near.health > 0 && weapons.dist(missile, near) <= w.def.fuzeRange;
            if (tripped || w.elapsed >= w.def.duration) {
                w.state = Weapon.State.Fuzing;
                w.fuzeTarget = tripped ? near : null;
                w.fuzeElapsed = 0;
                missile.commandedSteer = 0;
            }
        } else {
            w.fuzeElapsed += dt;
            if (w.fuzeElapsed >= w.def.fuzeTime) {
                weapons.detonate(missile);
                spent.push(missile);
            }
        }
    }

    // The semi-active seeker: re-homes every tick on the loudest (lowest
    // stealth) opposed return the owner's radar illuminates, inside
    // seekerRange. No return leaves the round flying straight; a destroyed
    // owner drops the illumination gate (plain homing).
    function seek(missile: Entity) {
        const w = missile.weapon;
        const best = weapons.bestReturn(missile, missile.owner, missile.side, w.def.seekerRange);
        w.target = best;
        if (best === null) {
            missile.commandedSteer = 0;
            return;
        }
        const error = weapons.wrap180(weapons.bearingTo(missile, best) - missile.heading);
        missile.commandedSteer = Math.max(-1, Math.min(1, error / weapons.cutAngle));
    }

    // Consumes raised launch intents: a guided round refuses (keeping its
    // charge) without an illuminated return to lock; a kinetic round fires
    // straight off the nose. The spawned missile inherits the launcher's
    // side, owns nothing and flies at full throttle from the rail.
    function consumeLaunches() {
        const roster = weapons.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            const launcher = roster[i];
            for (let j = 0; j < launcher.abilities.length; ++j) {
                const slot = launcher.abilities[j];
                if (!(slot.def instanceof AbilityLaunch) || !slot.pending)
                    continue;
                slot.pending = false;
                if (!slot.ready)
                    continue;
                const row = Database.weaponDataFor(slot.def.weapon);
                if (row === null)
                    continue;
                let target = null;
                if (row.guided) {
                    target = weapons.bestReturn(launcher, launcher, launcher.side, row.seekerRange);
                    if (target === null)
                        continue;
                }
                const missile = weapons.world.spawn("MSL", {
                    classification: row.classification,
                    side: launcher.side,
                    owner: launcher,
                    posX: launcher.posX,
                    posY: launcher.posY,
                    heading: target !== null ? weapons.bearingTo(launcher, target) : launcher.heading,
                    radarFov: 360,
                    kinetic: row.speed,
                    maneuver: row.turnRate,
                    durable: 1,
                    stealth: 8,
                    maxHealth: 20,
                    health: 20,
                    commandedThrottle: 1
                });
                missile.weapon = weapons.weaponFactory.createObject(missile, {
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
        weapons.detonations = [...weapons.detonations, weapons.detonationFactory.createObject(weapons, {
            worldX: missile.posX,
            worldY: missile.posY,
            blastRadius: w.def.blastRadius,
            life: weapons.detonationLife,
            maxLife: weapons.detonationLife
        })];
        for (let i = 0; i < weapons.world.entities.length; ++i) {
            const struck = weapons.world.entities[i];
            if (struck === missile || struck === missile.owner)
                continue;
            if (weapons.dist(missile, struck) <= w.def.blastRadius)
                struck.health = Math.max(0, struck.health - w.def.damage);
        }
    }

    // Despawns detonated rounds and anything killed this tick; entities
    // never given hull (maxHealth 0) and the invulnerable list are exempt.
    function reap(spent: var) {
        const roster = weapons.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            const entity = roster[i];
            if (spent.includes(entity))
                weapons.world.despawn(entity);
            else if (entity.maxHealth > 0 && entity.health <= 0 && !weapons.invulnerable.includes(entity))
                weapons.world.despawn(entity);
        }
    }

    function ageDetonations(dt: real) {
        let expired = false;
        for (let i = 0; i < weapons.detonations.length; ++i) {
            weapons.detonations[i].life -= dt;
            if (weapons.detonations[i].life <= 0)
                expired = true;
        }
        if (expired) {
            const dead = weapons.detonations.filter(d => d.life <= 0);
            weapons.detonations = weapons.detonations.filter(d => d.life > 0);
            dead.forEach(d => d.destroy());
        }
    }

    // The loudest opposed live return within range of at, gated by the
    // illuminator's radar cone; ties break to the nearest.
    function bestReturn(at: Entity, illuminator: Entity, side: int, range: real): Entity {
        let best = null;
        let bestDist = 0;
        for (let i = 0; i < weapons.world.entities.length; ++i) {
            const contact = weapons.world.entities[i];
            if (contact === at || contact === illuminator || contact.health <= 0)
                continue;
            if (!weapons.opposed(side, contact.side))
                continue;
            const d = weapons.dist(at, contact);
            if (d > range || !weapons.illuminated(illuminator, contact))
                continue;
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
        for (let i = 0; i < weapons.world.entities.length; ++i) {
            const contact = weapons.world.entities[i];
            if (contact === missile || contact === missile.owner || contact.health <= 0)
                continue;
            if (missile.owner !== null && contact.owner === missile.owner)
                continue;
            const d = weapons.dist(missile, contact);
            if (d <= bestDist) {
                best = contact;
                bestDist = d;
            }
        }
        return best;
    }

    // Whether the illuminator's radar cone paints the contact; a missing
    // illuminator is lenient, per briardart.
    function illuminated(illuminator: Entity, contact: Entity): bool {
        if (illuminator === null)
            return true;
        const off = weapons.wrap180(weapons.bearingTo(illuminator, contact) - illuminator.heading);
        return Math.abs(off) <= illuminator.radarFov / 2;
    }

    // Whether two sides shoot at each other: ownship and friendly versus
    // hostile; unknowns and neutrals engage no one.
    function opposed(a: int, b: int): bool {
        const friend = s => s === Side.Kind.Ownship || s === Side.Kind.Friendly;
        return (friend(a) && b === Side.Kind.Hostile) || (a === Side.Kind.Hostile && friend(b));
    }

    function bearingTo(from: Entity, to: Entity): real {
        return Math.atan2(to.posX - from.posX, -(to.posY - from.posY)) * 180 / Math.PI;
    }

    function wrap180(angle: real): real {
        return ((angle % 360) + 540) % 360 - 180;
    }

    function dist(a: Entity, b: Entity): real {
        return Math.hypot(b.posX - a.posX, b.posY - a.posY);
    }
}
