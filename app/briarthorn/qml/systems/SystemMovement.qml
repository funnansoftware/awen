import awen.entity
import "../model"

// Integrates every entity's control inputs into its pose each tick, scaled by
// frame time, within the limits its stats afford: heading turns at
// commandedSteer of the entity's turn rate, and speed closes on
// commandedThrottle of its top speed at the acceleration its maneuver rating
// buys. Every limit is read live, so a stat change takes effect the next tick.
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
