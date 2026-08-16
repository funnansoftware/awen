import awen.entity
import "../database"
import "../model"

// AI trigger discipline: every entity carrying an engageTarget invokes the
// launch ability its engageAbility names when that target is alive, inside
// the radar cone and within the named round's flight reach. A discrete
// launch is paced by the entity's own holdoff on top of the ability's
// cooldown, so no magazine is dumped in one pass; an automatic one is
// gripped instead — trigger held while every gate holds, let go the tick one
// fails — and its own cooldown is the rate of fire. An entity held by its
// engageHold flag stands down entirely, its pacing frozen with it.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    // The arena geometry radar cannot see through.
    property list<Obstacle> obstacles

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity.engageHold) {
                root.grip(entity, "");
                continue;
            }
            // The pacing runs in wall time, target or none — a sentry that
            // fired just before losing its lock must telegraph a later
            // re-engagement exactly like a first, not fire off the frozen
            // remainder of the old holdoff.
            entity.engageTimer = Math.max(0, entity.engageTimer - dt);
            // A targetless entity is not this system's shooter, and its
            // slots are never written — the player's craft lives here, its
            // own trigger held through the command bus.
            if (entity.engageTarget === null)
                continue;
            const def = Abilities.defFor(entity.engageAbility) as AbilityLaunch;
            const open = def !== null && root.cleared(entity, def);
            root.grip(entity, open && def.automatic ? entity.engageAbility : "");
            if (def === null || def.automatic)
                continue;
            if (!open || entity.engageTimer > 0)
                continue;
            root.fire(entity);
        }
    }

    // Whether every gate a launch needs is open: the target alive, the
    // selected round real, the range inside what it can physically fly, the
    // target inside the radar cone and the line to it clear of the arena's
    // pillars — ducking behind one denies the shot.
    function cleared(entity: Entity, def: AbilityLaunch): bool {
        const target = entity.engageTarget;
        if (target === null || target.health <= 0)
            return false;
        const round = Database.weaponDataFor(def.weapon);
        if (round === null)
            return false;
        if (Geo.distance(entity, target) > round.reach)
            return false;
        const off = Geo.wrap180(Geo.bearing(entity, target) - entity.heading);
        if (Math.abs(off) > entity.radarFov / 2)
            return false;
        return Geo.lineOfSight(entity, target, root.obstacles);
    }

    // Sets the trigger position across the entity's automatic slots: down on
    // the one carrying the named ability, up on every other — "" releases
    // them all, which is also what lets go when a stance switches the
    // selected ability away mid-burst. Written only on change, like every
    // per-tick mark.
    function grip(entity: Entity, name: string) {
        for (let i = 0; i < entity.abilities.length; ++i) {
            const slot = entity.abilities[i];
            if (slot.def === null || !slot.def.automatic)
                continue;
            const hold = slot.def.name === name;
            if (slot.held !== hold)
                slot.held = hold;
        }
    }

    // Raises the selected launch on its ready slot, winding the pacing back
    // up. A slot already holding a shot armed is left alone: it fires itself
    // the tick its lock appears, and asking again would only re-pace it.
    function fire(entity: Entity) {
        for (let i = 0; i < entity.abilities.length; ++i) {
            const slot = entity.abilities[i];
            if (slot.def.name === entity.engageAbility && slot.ready && !slot.armed) {
                slot.activate();
                entity.engageTimer = entity.engageHoldoff;
                return;
            }
        }
    }
}
