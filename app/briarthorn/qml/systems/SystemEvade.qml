import awen.entity
import "../model"

// Standoff evasion: every entity carrying an evadeTarget flies about it at
// full throttle — beyond its standoff it noses in, at it it rides the
// perimeter, well inside it turns tail — the 0..180 degree swing off the
// target's bearing blending across half the standoff. Ports briardart's
// ManeuverEvade.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    // Bearing error, in degrees, at which steer reaches full deflection.
    readonly property real cutAngle: 30

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity.evadeTarget === null)
                continue;
            const excess = Math.max(-1, Math.min(1, (Geo.distance(entity, entity.evadeTarget) - entity.evadeStandoff) / (entity.evadeStandoff / 2)));
            const desired = Geo.bearing(entity, entity.evadeTarget) + 90 * (1 - excess);
            const error = Geo.wrap180(desired - entity.heading);
            entity.commandedSteer = Math.max(-1, Math.min(1, error / root.cutAngle));
            entity.commandedThrottle = 1;
        }
    }
}
