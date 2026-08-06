import QtQml

// Cranking: hold the focus — a target, or an anchored point — near the edge
// of the own radar cone instead of on the nose, guidance kept while the
// closure is cut — offsetting to whichever side is the shorter swing from
// the current heading.
Maneuver {
    id: root

    // Degrees kept inside the cone's half-angle, so wander never drops the
    // focus out of illumination.
    property real margin: 10

    function desiredHeading(entity: Entity): real {
        const bearing = Geo.bearingFrom(entity.posX, entity.posY, root.focusX(), root.focusY());
        const offset = Math.max(0, entity.radarFov / 2 - root.margin);
        const right = Geo.wrap180(bearing + offset - entity.heading);
        const left = Geo.wrap180(bearing - offset - entity.heading);
        return Math.abs(right) <= Math.abs(left) ? bearing + offset : bearing - offset;
    }
}
