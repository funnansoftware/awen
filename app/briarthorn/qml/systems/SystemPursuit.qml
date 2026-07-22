import awen.entity
import "../model"

// Pure-pursuit behaviour: flies its entity toward the target at full
// throttle, steer saturating once the target sits more than cutAngle off the
// nose.
System {
    id: pursuit

    // The entity being flown and the entity it chases.
    required property Entity entity
    required property Entity target

    // Bearing error, in degrees, at which steer reaches full deflection.
    readonly property real cutAngle: 30

    function update(dt: real) {
        const dx = pursuit.target.posX - pursuit.entity.posX;
        const dy = pursuit.target.posY - pursuit.entity.posY;
        const bearing = Math.atan2(dx, -dy) * 180 / Math.PI;
        const error = (((bearing - pursuit.entity.heading) % 360) + 540) % 360 - 180;
        pursuit.entity.commandedSteer = Math.max(-1, Math.min(1, error / pursuit.cutAngle));
        pursuit.entity.commandedThrottle = 1;
    }
}
