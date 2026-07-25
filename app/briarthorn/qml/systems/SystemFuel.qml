import awen.entity
import "../database"
import "../model"

// Fuel burn: the tank drains each tick at the rate the craft's kinetic rating
// affords — a steady cruise draw, multiplied up under throttle — clamped at
// empty. The sole writer of fuel; the condition readout reads it.
System {
    id: fuel

    // The craft whose tank this drains.
    required property Entity entity

    function update(dt: real) {
        const throttle = Math.max(0, Math.min(1, fuel.entity.commandedThrottle));
        const draw = fuel.entity.fuelBurn * (1 + GameRules.fuelThrottleBurn * throttle);
        fuel.entity.fuel = Math.max(0, fuel.entity.fuel - draw * dt);
    }
}
