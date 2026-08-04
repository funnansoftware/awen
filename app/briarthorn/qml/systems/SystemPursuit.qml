import awen.entity
import "../model"

// Pure-pursuit behaviour: every entity carrying a pursuitTarget flies toward
// it at full throttle, steer saturating once the target sits more than
// cutAngle off the nose.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    // Bearing error, in degrees, at which steer reaches full deflection.
    readonly property real cutAngle: 30

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity.pursuitTarget === null)
                continue;
            const error = Geo.wrap180(Geo.bearing(entity, entity.pursuitTarget) - entity.heading);
            entity.commandedSteer = Math.max(-1, Math.min(1, error / root.cutAngle));
            entity.commandedThrottle = 1;
        }
    }
}
