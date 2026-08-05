import QtQml

// Base movement behaviour an entity carries on its maneuvers list: each tick
// SystemManeuver hands the stick to the first engaged one, which writes the
// steer and throttle commands SystemMovement integrates. A derived maneuver
// overrides desiredHeading() — or fly() itself when full throttle toward a
// heading is not its shape.
QtObject {
    id: root

    // The craft this maneuver flies relative to; null stands it down.
    property Entity target: null

    // Whether this maneuver wants the stick this tick.
    property bool engaged: root.target !== null

    // Bearing error, in degrees, at which steer reaches full deflection.
    readonly property real cutAngle: 30

    // Flies the entity for one tick: onto the desired heading at full throttle.
    function fly(entity: Entity, dt: real) {
        root.steerToward(entity, root.desiredHeading(entity));
        entity.commandedThrottle = 1;
    }

    // The heading this maneuver flies for; the base holds course.
    function desiredHeading(entity: Entity): real {
        return entity.heading;
    }

    // Writes the steer that turns the entity onto a desired heading.
    function steerToward(entity: Entity, desired: real) {
        const error = Geo.wrap180(desired - entity.heading);
        entity.commandedSteer = Math.max(-1, Math.min(1, error / root.cutAngle));
    }
}
