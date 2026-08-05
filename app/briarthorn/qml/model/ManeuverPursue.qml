import QtQml

// Pure pursuit: fly straight at the focus — a target, or an anchored
// waypoint — steer saturating once it sits more than cutAngle off the nose.
Maneuver {
    id: root

    function desiredHeading(entity: Entity): real {
        return Geo.bearingFrom(entity.posX, entity.posY, root.focusX(), root.focusY());
    }
}
