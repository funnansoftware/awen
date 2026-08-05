import QtQml

// Standoff evasion: fly about the focus — a target, or an anchored point —
// beyond the standoff nose in, at it ride the perimeter, well inside turn
// tail — the 0..180 degree swing off its bearing blending across half the
// standoff. Ports briardart's ManeuverEvade.
Maneuver {
    id: root

    // Metres held off the focus.
    property real standoff: 12000

    function desiredHeading(entity: Entity): real {
        const excess = Math.max(-1, Math.min(1, (Geo.distanceFrom(entity.posX, entity.posY, root.focusX(), root.focusY()) - root.standoff) / (root.standoff / 2)));
        return Geo.bearingFrom(entity.posX, entity.posY, root.focusX(), root.focusY()) + 90 * (1 - excess);
    }
}
