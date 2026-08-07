import awen.entity
import "../database"
import "../model"

// Threat sensing and the defensive reflex: a mark pass pins the nearest
// round inside each target's detection envelope onto its threatInbound —
// the one inbound fact both the flare reflex below and SystemPersonality
// read. A locked round threatens exactly its lock; an unlocked one — a
// kinetic slug, or a guided round flying blind — threatens every opposed
// entity that detects it, since nothing says where it will pass. Then every
// entity carrying the threatReflex flag pops its flare once its marked round
// closes inside threatRange, with a per-entity holdoff so consecutive pops
// give each decoy a chance to steal the lock before the next one burns —
// only against guided rounds, as a slug carries no seeker to seduce.
System {
    id: root

    // The world's roster — both the defended entities and the sky scanned
    // for the rounds homing on them.
    property list<Entity> entities

    // Metres at which an inbound homing round triggers a pop.
    property real threatRange: 9000

    // Minimum seconds between one entity's pops.
    property real holdoff: 1.5

    function update(dt: real) {
        root.mark();
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (!entity.threatReflex)
                continue;
            entity.threatTimer = Math.max(0, entity.threatTimer - dt);
            if (entity.threatTimer > 0)
                continue;
            if (entity.threatInbound !== null && entity.threatInbound.weapon.def.guided && Geo.distance(entity, entity.threatInbound) <= root.threatRange)
                root.pop(entity);
        }
    }

    // Pins each entity's nearest threatening round within its detection
    // range, writing only real changes — a defeated round drops off, but a
    // held mark is never cleared and repinned in place, which would flicker
    // every binding on it (and restart any animation gated by one) once a
    // tick.
    function mark() {
        const nearest = new Map();
        for (let i = 0; i < root.entities.length; ++i) {
            const missile = root.entities[i];
            if (missile.weapon === null)
                continue;
            if (missile.weapon.target !== null) {
                root.consider(nearest, missile.weapon.target, missile);
                continue;
            }
            for (let j = 0; j < root.entities.length; ++j) {
                const target = root.entities[j];
                if (root.opposed(missile.side, target.side))
                    root.consider(nearest, target, missile);
            }
        }
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            const mark = nearest.get(entity);
            const next = mark !== undefined ? mark : null;
            if (entity.threatInbound !== next)
                entity.threatInbound = next;
        }
    }

    // Holds the round against the target's mark if the target detects it and
    // no nearer round is already held.
    function consider(nearest: var, target: Entity, missile: Entity) {
        const range = Geo.distance(missile, target);
        if (range > target.detectionRange)
            return;
        const held = nearest.get(target);
        if (held === undefined || range < Geo.distance(target, held))
            nearest.set(target, missile);
    }

    // Whether two sides shoot at each other: ownship and friendly versus
    // hostile; unknowns and neutrals engage no one.
    function opposed(a: int, b: int): bool {
        const friend = s => s === Side.Kind.Ownship || s === Side.Kind.Friendly;
        return (friend(a) && b === Side.Kind.Hostile) || (a === Side.Kind.Hostile && friend(b));
    }

    // Burns one flare off the first ready countermeasure slot.
    function pop(entity: Entity) {
        for (let i = 0; i < entity.abilities.length; ++i) {
            const slot = entity.abilities[i];
            if (slot.def instanceof AbilityCountermeasure && slot.ready) {
                slot.activate();
                entity.threatTimer = root.holdoff;
                return;
            }
        }
    }
}
