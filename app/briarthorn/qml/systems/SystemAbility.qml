import awen.entity
import "../model"

// Ability timekeeping: runs every entity's slot cooldowns down toward
// ready. The consuming systems (weapon, countermeasure) spend charges and
// wind the cooldowns back up.
System {
    id: ability

    // The world whose entities carry the slots.
    required property World world

    function update(dt: real) {
        for (let i = 0; i < ability.world.entities.length; ++i) {
            const slots = ability.world.entities[i].abilities;
            for (let j = 0; j < slots.length; ++j) {
                if (slots[j].cooldownRemaining > 0)
                    slots[j].cooldownRemaining = Math.max(0, slots[j].cooldownRemaining - dt);
            }
        }
    }
}
