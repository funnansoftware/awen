import QtQml

// Flight: fly directly away from the target, tail square to its bearing.
Maneuver {
    id: root

    function desiredHeading(entity: Entity): real {
        return Geo.reciprocal(Geo.bearing(entity, root.target));
    }
}
