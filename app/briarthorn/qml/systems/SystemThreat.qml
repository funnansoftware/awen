import awen.entity
import "../model"

// Defensive reflex: pops the entity's flare once a hostile missile homing
// on it closes inside threatRange, with a holdoff so consecutive pops give
// each decoy a chance to steal the lock before the next one burns.
System {
    id: threat

    // The defended entity and the world scanned for inbound rounds.
    required property Entity entity
    required property World world

    // Metres at which an inbound homing round triggers a pop.
    property real threatRange: 9000

    // Minimum seconds between pops.
    property real holdoff: 1.5

    property real timer: 0

    function update(dt: real) {
        threat.timer = Math.max(0, threat.timer - dt);
        if (threat.timer > 0)
            return;
        for (let i = 0; i < threat.world.entities.length; ++i) {
            const missile = threat.world.entities[i];
            if (missile.weapon === null || missile.weapon.target !== threat.entity)
                continue;
            const dx = missile.posX - threat.entity.posX;
            const dy = missile.posY - threat.entity.posY;
            if (Math.hypot(dx, dy) > threat.threatRange)
                continue;
            for (let j = 0; j < threat.entity.abilities.length; ++j) {
                const slot = threat.entity.abilities[j];
                if (slot.def instanceof AbilityFlare && slot.ready) {
                    slot.activate();
                    threat.timer = threat.holdoff;
                    return;
                }
            }
            return;
        }
    }
}
