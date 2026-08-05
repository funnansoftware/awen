import awen.entity
import "../database"
import "../model"

// Threat sensing and the defensive reflex: a mark pass pins the nearest
// homing round inside each target's detection envelope onto its
// threatInbound — the one inbound fact both the flare reflex below and
// SystemPersonality read — then every entity carrying the threatReflex flag
// pops its flare once its marked round closes inside threatRange, with a
// per-entity holdoff so consecutive pops give each decoy a chance to steal
// the lock before the next one burns.
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
            if (entity.threatInbound !== null && Geo.distance(entity, entity.threatInbound) <= root.threatRange)
                root.pop(entity);
        }
    }

    // Pins each entity's nearest homing round within its detection range,
    // clearing yesterday's marks first so a defeated round drops off.
    function mark() {
        for (let i = 0; i < root.entities.length; ++i)
            root.entities[i].threatInbound = null;
        for (let i = 0; i < root.entities.length; ++i) {
            const missile = root.entities[i];
            if (missile.weapon === null || missile.weapon.target === null)
                continue;
            const target = missile.weapon.target;
            const range = Geo.distance(missile, target);
            if (range > target.detectionRange)
                continue;
            if (target.threatInbound === null || range < Geo.distance(target, target.threatInbound))
                target.threatInbound = missile;
        }
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
