import awen.entity
import "../database"
import "../model"

// Integrates every entity's control inputs into its pose each tick, scaled by
// frame time, within the limits its stats afford: heading turns at
// commandedSteer of the entity's turn rate, the airframe banks into that turn,
// and speed closes on commandedThrottle of its top speed at the acceleration
// its maneuver rating buys. Every limit is read live, so a stat change takes
// effect the next tick.
System {
    id: root

    // The entities to integrate.
    property list<Entity> entities

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i)
            root.advance(root.entities[i], dt);
    }

    function advance(entity: Entity, dt: real) {
        const steer = Math.max(-1, Math.min(1, entity.commandedSteer));
        entity.heading = Geo.wrap360(entity.heading + (steer * entity.turnRate * dt));

        // The airframe rolls into the turn rather than snapping over: full
        // deflection leans it to full bank, a centred stick rolls it level
        // again, and both take the same rate. Attitude only — the heading
        // above turns on the stick, not on the lean — but it is integrated
        // here with the rest of the pose so a paused game holds its bank.
        const bank = steer * GameRules.maxBank;
        const roll = GameRules.bankRate * dt;
        entity.bank = bank > entity.bank ? Math.min(bank, entity.bank + roll) : Math.max(bank, entity.bank - roll);

        // Throttle commands a speed the airframe has to fly up to — and coast
        // back down to — rather than one it snaps to.
        const throttle = Math.max(0, Math.min(1, entity.commandedThrottle));
        const target = throttle * entity.topSpeed;
        const step = entity.acceleration * dt;
        entity.speed = target > entity.speed ? Math.min(target, entity.speed + step) : Math.max(target, entity.speed - step);

        entity.posX += Geo.offsetX(entity.heading, entity.speed * dt);
        entity.posY += Geo.offsetY(entity.heading, entity.speed * dt);
    }
}
