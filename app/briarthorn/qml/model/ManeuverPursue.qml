import QtQml

// Pure pursuit: fly straight at the target, steer saturating once it sits
// more than cutAngle off the nose.
Maneuver {
    id: root

    function desiredHeading(entity: Entity): real {
        return Geo.bearing(entity, root.target);
    }
}
