import awen.entity
import "../database"
import "../model"

// Defensive reflex: every entity carrying the threatReflex flag pops its
// flare once a hostile missile homing on it closes inside threatRange, with
// a per-entity holdoff so consecutive pops give each decoy a chance to
// steal the lock before the next one burns.
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
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (!entity.threatReflex)
                continue;
            entity.threatTimer = Math.max(0, entity.threatTimer - dt);
            if (entity.threatTimer > 0)
                continue;
            if (root.inboundOn(entity))
                root.pop(entity);
        }
    }

    // Whether any homing round targeting the entity has closed inside range.
    function inboundOn(entity: Entity): bool {
        for (let i = 0; i < root.entities.length; ++i) {
            const missile = root.entities[i];
            if (missile.weapon === null || missile.weapon.target !== entity)
                continue;
            if (Geo.distance(missile, entity) <= root.threatRange)
                return true;
        }
        return false;
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
