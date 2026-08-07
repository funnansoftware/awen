import awen.entity
import "../database"
import "../model"

// AI trigger discipline: every entity carrying an engageTarget invokes its
// named launch ability when that target is alive, inside the radar cone and
// within engageRange — paced by the entity's own holdoff on top of the
// ability's cooldown, so no magazine is dumped in one pass. An entity held
// by its engageHold flag stands down entirely, its pacing frozen with it.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    // The arena geometry radar cannot see through.
    property list<Obstacle> obstacles

    // The launch ability invoked, by registry name, and the round it spawns;
    // the cast is null for a name that is not a launch at all.
    property string ability: "guided"
    readonly property AbilityLaunch def: Abilities.defFor(root.ability) as AbilityLaunch
    readonly property DataWeapon round: root.def ? Database.weaponDataFor(root.def.weapon) : null

    // Maximum firing range, metres: by default as far as that round can
    // physically fly, so the envelope tracks the weapon's own tuning.
    property real engageRange: root.round ? root.round.reach : 0

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity.engageTarget === null || entity.engageHold)
                continue;
            entity.engageTimer = Math.max(0, entity.engageTimer - dt);
            if (entity.engageTimer > 0 || entity.engageTarget.health <= 0)
                continue;
            if (Geo.distance(entity, entity.engageTarget) > root.engageRange)
                continue;
            const off = Geo.wrap180(Geo.bearing(entity, entity.engageTarget) - entity.heading);
            if (Math.abs(off) > entity.radarFov / 2)
                continue;
            // A pillar between shooter and target breaks the radar picture
            // the shot needs, so ducking behind one denies the launch.
            if (!Geo.lineOfSight(entity, entity.engageTarget, root.obstacles))
                continue;
            root.fire(entity);
        }
    }

    // Raises the named launch on its ready slot, winding the pacing back up.
    function fire(entity: Entity) {
        for (let i = 0; i < entity.abilities.length; ++i) {
            const slot = entity.abilities[i];
            if (slot.def.name === root.ability && slot.ready) {
                slot.activate();
                entity.engageTimer = entity.engageHoldoff;
                return;
            }
        }
    }
}
