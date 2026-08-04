import awen.entity
import "../model"

// Standoff evasion: flies its entity about the target at full throttle —
// beyond the standoff it noses in, at it it rides the perimeter, well inside
// it turns tail — the 0..180 degree swing off the target's bearing blending
// across half the standoff. Ports briardart's ManeuverEvade. With no target
// it holds course.
System {
    id: root

    // The entity being flown and the threat it holds off; null flies straight.
    required property Entity entity
    property Entity target: null

    // The orbit distance held off the target, metres.
    property real standoff: 12000

    // Bearing error, in degrees, at which steer reaches full deflection.
    readonly property real cutAngle: 30

    function update(dt: real) {
        root.entity.commandedThrottle = 1;
        if (root.target === null) {
            root.entity.commandedSteer = 0;
            return;
        }
        const excess = Math.max(-1, Math.min(1, (Geo.distance(root.entity, root.target) - root.standoff) / (root.standoff / 2)));
        const desired = Geo.bearing(root.entity, root.target) + 90 * (1 - excess);
        const error = Geo.wrap180(desired - root.entity.heading);
        root.entity.commandedSteer = Math.max(-1, Math.min(1, error / root.cutAngle));
    }
}
