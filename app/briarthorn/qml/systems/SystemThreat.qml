import awen.entity
import "../database"
import "../model"

// Defensive reflex: pops the entity's flare once a hostile missile homing
// on it closes inside threatRange, with a holdoff so consecutive pops give
// each decoy a chance to steal the lock before the next one burns.
System {
    id: root

    // The defended entity and the world scanned for inbound rounds.
    required property Entity entity
    required property World world

    // Metres at which an inbound homing round triggers a pop.
    property real threatRange: 9000

    // Minimum seconds between pops.
    property real holdoff: 1.5

    property real timer: 0

    function update(dt: real) {
        root.timer = Math.max(0, root.timer - dt);
        if (root.timer > 0)
            return;
        for (let i = 0; i < root.world.entities.length; ++i) {
            const missile = root.world.entities[i];
            if (missile.weapon === null || missile.weapon.target !== root.entity)
                continue;
            const dx = missile.posX - root.entity.posX;
            const dy = missile.posY - root.entity.posY;
            if (Math.hypot(dx, dy) > root.threatRange)
                continue;
            for (let j = 0; j < root.entity.abilities.length; ++j) {
                const slot = root.entity.abilities[j];
                if (slot.def instanceof AbilityCountermeasure && slot.ready) {
                    slot.activate();
                    root.timer = root.holdoff;
                    return;
                }
            }
            return;
        }
    }
}
