import QtQml

// Standoff evasion: fly about the target — beyond the standoff nose in, at it
// ride the perimeter, well inside turn tail — the 0..180 degree swing off the
// target's bearing blending across half the standoff. Ports briardart's
// ManeuverEvade.
Maneuver {
    id: root

    // Metres held off the target.
    property real standoff: 12000

    function desiredHeading(entity: Entity): real {
        const excess = Math.max(-1, Math.min(1, (Geo.distance(entity, root.target) - root.standoff) / (root.standoff / 2)));
        return Geo.bearing(entity, root.target) + 90 * (1 - excess);
    }
}
