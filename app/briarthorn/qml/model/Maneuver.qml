import QtQml

// Base movement behaviour an entity carries on its maneuvers list: each tick
// SystemManeuver hands the stick to the first engaged one, which writes the
// steer and throttle commands SystemMovement integrates. A derived maneuver
// overrides desiredHeading() — or fly() itself when full throttle toward a
// heading is not its shape.
QtObject {
    id: root

    // The craft this maneuver flies relative to; null stands it down unless
    // a point is anchored below.
    property Entity target: null

    // A fixed world point flown when no target is set — a waypoint, patrol
    // station or avoid area. Scenario- and director-armed only: a
    // personality disengages its stances by nulling target, so its
    // maneuvers must stay anchor-free.
    property real anchorX: 0
    property real anchorY: 0
    property bool anchored: false

    // Whether this maneuver wants the stick this tick.
    property bool engaged: root.target !== null || root.anchored

    // Bearing error, in degrees, at which steer reaches full deflection.
    readonly property real cutAngle: 30

    // Where the maneuver flies relative to: the target when one is set, the
    // anchored point otherwise.
    function focusX(): real {
        return root.target !== null ? root.target.posX : root.anchorX;
    }

    function focusY(): real {
        return root.target !== null ? root.target.posY : root.anchorY;
    }

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
