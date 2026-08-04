import awen.entity
import "../database"
import "../model"

// Fuel burn: every entity carrying the burnsFuel aspect drains its tank each
// tick at the rate its kinetic rating affords — a steady cruise draw,
// multiplied up under throttle — clamped at empty. The launch screen's demo
// craft clears the flag rather than any scenario unloading this system.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (!entity.burnsFuel || entity.maxFuel <= 0)
                continue;
            const throttle = Math.max(0, Math.min(1, entity.commandedThrottle));
            const draw = entity.fuelBurn * (1 + GameRules.fuelThrottleBurn * throttle);
            entity.fuel = Math.max(0, entity.fuel - draw * dt);
        }
    }
}
