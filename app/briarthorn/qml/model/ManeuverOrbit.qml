import QtQml

// Patrol orbit: fly to the focus — a target, or an anchored station — and
// ride a ring at the standoff around it, easing onto the cruise throttle on
// station. A ring is only flyable above the airframe's turning circle
// (speed over turn rate), which is what cruise is for: slower buys tighter.
Maneuver {
    id: root

    // The ring radius, metres — named as ManeuverEvade's so a personality
    // stance prices it the same way.
    property real standoff: 9000

    // Throttle ridden on station; the transit out to the ring flies at
    // full and blends down on arrival.
    property real cruise: 0.6

    // Which way the ring is ridden, as seen on the scope.
    property bool clockwise: true

    function fly(entity: Entity, dt: real) {
        const range = Geo.distanceFrom(entity.posX, entity.posY, root.focusX(), root.focusY());
        const bearing = Geo.bearingFrom(entity.posX, entity.posY, root.focusX(), root.focusY());
        const excess = Math.max(-1, Math.min(1, (range - root.standoff) / (root.standoff / 2)));
        // The 0..180 swing off the focus bearing, as ManeuverEvade's; its
        // sign picks the ring direction.
        const swing = 90 * (1 - excess);
        root.steerToward(entity, bearing + (root.clockwise ? -swing : swing));
        entity.commandedThrottle = root.cruise + (1 - root.cruise) * Math.max(0, excess);
    }
}
