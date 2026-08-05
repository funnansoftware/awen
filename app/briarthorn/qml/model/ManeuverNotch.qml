import QtQml

// Notching: hold the target on the beam — flight path perpendicular to its
// bearing, the zero-closure aspect — turning whichever way is the shorter
// swing from the current heading.
Maneuver {
    id: root

    function desiredHeading(entity: Entity): real {
        const bearing = Geo.bearing(entity, root.target);
        const right = Geo.wrap180(Geo.perpendicularRight(bearing) - entity.heading);
        const left = Geo.wrap180(Geo.perpendicularLeft(bearing) - entity.heading);
        return Math.abs(right) <= Math.abs(left) ? Geo.perpendicularRight(bearing) : Geo.perpendicularLeft(bearing);
    }
}
