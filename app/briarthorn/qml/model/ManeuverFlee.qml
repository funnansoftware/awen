import QtQml

// Flight: fly directly away from the focus — a target, or an anchored area
// to avoid — tail square to its bearing.
Maneuver {
    id: root

    function desiredHeading(entity: Entity): real {
        return Geo.reciprocal(Geo.bearingFrom(entity.posX, entity.posY, root.focusX(), root.focusY()));
    }
}
