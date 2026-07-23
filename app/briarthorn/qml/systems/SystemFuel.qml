import awen.entity
import "../model"

// Fuel burn: the entity's tank drains each tick — a steady idle draw plus more
// under throttle — clamped at empty. The sole writer of fuel; the condition
// readout reads it.
System {
    id: fuel

    // The craft whose tank this drains.
    required property Entity entity

    // Units per second: the always-on draw and the extra at full throttle.
    property real idleBurn: 0.5
    property real throttleBurn: 4

    function update(dt: real) {
        const draw = fuel.idleBurn + fuel.throttleBurn * Math.max(0, fuel.entity.commandedThrottle);
        fuel.entity.fuel = Math.max(0, fuel.entity.fuel - draw * dt);
    }
}
