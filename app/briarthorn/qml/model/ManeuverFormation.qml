import QtQml

// Formation flight: hold a station placed off the target's nose. Far out it
// pursues the station point; closing, the aim eases onto the leader's heading
// while the throttle trims the along-nose gap to hold the slot.
Maneuver {
    id: root

    // The station: degrees clockwise off the leader's nose and metres out —
    // the default is the leader's right-rear quarter.
    property real station: 135
    property real spacing: 900

    // Metres over which station pursuit eases onto the leader's heading and
    // the throttle trim saturates.
    property real capture: 600

    function fly(entity: Entity, dt: real) {
        const stationX = root.target.posX + Geo.offsetX(root.target.heading + root.station, root.spacing);
        const stationY = root.target.posY + Geo.offsetY(root.target.heading + root.station, root.spacing);
        const gap = Geo.distanceFrom(entity.posX, entity.posY, stationX, stationY);
        const aim = Geo.bearingFrom(entity.posX, entity.posY, stationX, stationY);
        const blend = Math.min(1, gap / root.capture);
        root.steerToward(entity, root.target.heading + blend * Geo.wrap180(aim - root.target.heading));
        // The station's reach along the entity's own nose: ahead runs the
        // throttle up over the leader's pace, astern runs it down.
        const ahead = gap * Math.cos((aim - entity.heading) * Math.PI / 180);
        entity.commandedThrottle = Math.max(0, Math.min(1, root.target.speed / entity.topSpeed + ahead / root.capture));
    }
}
