import QtQml

// Notching: hold the focus — a target, or an anchored point — on the beam,
// flight path perpendicular to its bearing, the zero-closure aspect —
// turning whichever way is the shorter swing from the current heading.
Maneuver {
    id: root

    function desiredHeading(entity: Entity): real {
        const bearing = Geo.bearingFrom(entity.posX, entity.posY, root.focusX(), root.focusY());
        const right = Geo.wrap180(Geo.perpendicularRight(bearing) - entity.heading);
        const left = Geo.wrap180(Geo.perpendicularLeft(bearing) - entity.heading);
        return Math.abs(right) <= Math.abs(left) ? Geo.perpendicularRight(bearing) : Geo.perpendicularLeft(bearing);
    }
}
