import awen.entity
import "../database"
import "../model"

// The sentry radar: every entity carrying the sentry aspect either sweeps —
// full deflection, so the maneuver rating alone prices the revolution — or
// slews onto the target its volume caught. The radar state is engageTarget
// itself: null is the search, a target is the track, and every consequence
// follows from machinery that already exists — SystemEngage fires at it,
// SystemWeapon illuminates rounds down the same nose, and dropping it back
// to null is what "resumes the sweep" means, from wherever the slew left
// the antenna pointed.
//
// A track is not yet a shot: the search volume reaches far past what the
// round on the rail can catch, so the trigger is held on engageHold until
// the track is inside the engagement ring GameRules prices. A craft is
// followed across the whole volume and fired on only in its heart.
//
// Runs before SystemEngage so the trigger sees this tick's track — the fresh
// engageTarget and its grace-floored pacing; the wedge itself is judged
// against last tick's heading, since SystemMovement integrates the slew
// after the trigger runs.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    // The arena geometry radar cannot see through.
    property list<Obstacle> obstacles

    // Degrees off the nose at which the tracking slew saturates — a seeker's
    // cut, tighter than a flown maneuver's.
    readonly property real cutAngle: 20

    // Seconds every fresh lock telegraphs before the first launch: the pacing
    // timer is floored to this on the acquire edge, so a re-lock can never
    // fire the tick it lands however long the last track ran the timer down.
    property real grace: 3

    // The hold volume stretches this far past the acquisition volume in
    // range and wedge both, so a target riding a rim crosses one edge going
    // out and another coming back in rather than flickering the lock on one.
    property real holdMargin: 1.08

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (!entity.sentry)
                continue;
            if (entity.health <= 0) {
                // Backstop for a scripted health write: an in-game kill
                // despawns the site inside SystemWeapon the same tick, so
                // this branch never sees one — but a corpse left enrolled
                // must still hold nothing and intend nothing.
                if (entity.engageTarget !== null)
                    entity.engageTarget = null;
                root.standDown(entity);
                continue;
            }
            const next = root.tracked(entity);
            if (entity.engageTarget !== next) {
                // Every change of track stands the rack down first — a track
                // handed straight from one target to another never passes
                // null, and intent armed against the old target must not
                // fire itself at the new one unpaced.
                root.standDown(entity);
                entity.engageTarget = next;
                if (next !== null)
                    entity.engageTimer = Math.max(entity.engageTimer, root.grace);
            }
            if (next !== null) {
                const error = Geo.wrap180(Geo.bearing(entity, next) - entity.heading);
                entity.commandedSteer = Math.max(-1, Math.min(1, error / root.cutAngle));
                // Held out of the engagement ring, released inside it, with
                // the same margin the track carries so the trigger does not
                // chatter on the boundary. The hold freezes the pacing, so a
                // lock's grace is spent where it matters: on the way in.
                const fire = GameRules.sentryFireRangeFor(entity.detectionRange);
                entity.engageHold = Geo.distance(entity, next) > (entity.engageHold ? fire : fire * root.holdMargin);
            } else {
                entity.commandedSteer = 1;
                // Nothing to hold: the pacing runs down through the search so
                // a battery that has been quiet opens on its own telegraph.
                entity.engageHold = false;
            }
        }
    }

    // The contact the radar holds this tick: the held target while it stays
    // inside the stretched volume, else whatever the acquisition volume
    // catches, else null. Losing and catching in the same tick hands the
    // track over without a sweep between — the dish is already pointing
    // wherever that could be true.
    function tracked(entity: Entity): Entity {
        const held = entity.engageTarget;
        if (held !== null && held.health > 0 && root.inVolume(entity, held, entity.detectionRange * root.holdMargin, root.holdMargin))
            return held;
        return root.acquire(entity);
    }

    // The nearest live opposed craft inside the acquisition volume — craft,
    // not rounds or decoys: a search radar tracks intruders, and what a
    // seeker prefers stays the seeker's business.
    function acquire(entity: Entity): Entity {
        let best = null;
        let bestRange = Infinity;
        for (let i = 0; i < root.entities.length; ++i) {
            const contact = root.entities[i];
            if (contact === entity || contact.health <= 0 || contact.weapon !== null || contact.decoy)
                continue;
            if (!root.opposed(entity.side, contact.side))
                continue;
            const range = Geo.distance(entity, contact);
            if (range < bestRange && root.inVolume(entity, contact, entity.detectionRange, 1)) {
                best = contact;
                bestRange = range;
            }
        }
        return best;
    }

    // The radar volume at a given reach: inside the wedge off the nose and in
    // line of sight — the same three gates the sensor and trigger systems
    // spell for themselves. The hold path passes its margin so the wedge
    // stretches with the range and a target riding either edge crosses two
    // thresholds rather than flickering the lock on one; sight has no soft
    // edge — a shadow is entered, not drifted over.
    function inVolume(entity: Entity, contact: Entity, reach: real, wedgeMargin: real): bool {
        if (Geo.distance(entity, contact) > reach)
            return false;
        const off = Geo.wrap180(Geo.bearing(entity, contact) - entity.heading);
        return Math.abs(off) <= wedgeMargin * entity.radarFov / 2 && Geo.lineOfSight(entity, contact, root.obstacles);
    }

    // Whether two sides shoot at each other: ownship and friendly versus
    // hostile; unknowns and neutrals engage no one.
    function opposed(a: int, b: int): bool {
        const friend = s => s === Side.Kind.Ownship || s === Side.Kind.Friendly;
        return (friend(a) && b === Side.Kind.Hostile) || (a === Side.Kind.Hostile && friend(b));
    }

    // No launch intent survives a change of track: a slot the trigger armed
    // against a stale survey would otherwise fire itself at the next return
    // the radar happens across — unpaced, and at the survey's own reach
    // rather than the volume's.
    function standDown(entity: Entity) {
        for (let i = 0; i < entity.abilities.length; ++i) {
            if (entity.abilities[i].armed)
                entity.abilities[i].armed = false;
        }
    }
}
