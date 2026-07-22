import awen.entity
import "../model"

// Integrates every entity's control inputs into its pose each tick, scaled by
// frame time: heading turns at commandedSteer * maneuver deg/s and position
// advances along heading at commandedThrottle * kinetic px/s.
System {
    id: movement

    // The entities to integrate.
    property list<Entity> entities

    function update(dt: real) {
        for (let i = 0; i < movement.entities.length; ++i) {
            const entity = movement.entities[i];
            const turned = entity.heading + (entity.commandedSteer * entity.maneuver * dt);
            entity.heading = ((turned % 360) + 360) % 360;
            const speed = entity.commandedThrottle * entity.kinetic;
            const rad = entity.heading * Math.PI / 180;
            entity.posX += Math.sin(rad) * speed * dt;
            entity.posY -= Math.cos(rad) * speed * dt;
        }
    }
}
