import awen.entity
import "../model"

// Ability timekeeping: runs every entity's slot cooldowns down toward
// ready. The consuming systems (weapon, countermeasure) spend charges and
// wind the cooldowns back up.
System {
    id: root

    // The world whose entities carry the slots.
    required property World world

    function update(dt: real) {
        for (let i = 0; i < root.world.entities.length; ++i) {
            const slots = root.world.entities[i].abilities;
            for (let j = 0; j < slots.length; ++j) {
                const slot = slots[j];
                if (slot.cooldownRemaining > 0)
                    slot.cooldownRemaining = Math.max(0, slot.cooldownRemaining - dt);
                // A shot held on an empty rack is waiting on a check that can
                // never pass again, so it stands down rather than leaving a
                // lit control over a magazine with nothing in it.
                if (slot.armed && slot.charges === 0)
                    slot.armed = false;
            }
        }
    }
}
