import QtQml

// Ground-truth state for one object in the game world: identity, pose,
// control inputs and the six stats. Pure state — systems write it, the view
// reads it.
QtObject {
    // Identity.
    property string callsign: ""
    property int classification: Classification.Kind.Unknown
    property int side: Side.Kind.Unknown

    // World position in metres (1 px = 1 m, +x east, +y south) and facing in
    // degrees clockwise from north, kept in [0, 360).
    property real posX: 0
    property real posY: 0
    property real heading: 0

    // The radar's total field-of-view cone in degrees, centred on heading;
    // 360 is an all-round sensor.
    property real radarFov: 360

    // Control inputs a pilot or behaviour system writes and SystemMovement
    // integrates: throttle 0..1, steer -1 (left) to 1 (right).
    property real commandedThrottle: 0
    property real commandedSteer: 0

    // The six stats, as direct game quantities: kinetic is the full-throttle
    // speed in m/s, maneuver the full-deflection turn rate in deg/s, sensor
    // the radar detection range in metres, durable scales maxHealth at spawn
    // and stealth is the emission signature — lower is louder, and a guided
    // seeker homes on the loudest illuminated return; compute waits on the
    // system that will read it.
    property real kinetic: 0
    property real maneuver: 0
    property real durable: 0
    property real compute: 0
    property real sensor: 0
    property real stealth: 0

    // Condition: current and maximum hull integrity and fuel. Pure state —
    // SystemWeapon's blasts write health, SystemFuel writes fuel, the view
    // reads both. maxHealth derives from durable at spawn; both start full.
    property real health: 0
    property real maxHealth: 0
    property real fuel: 0
    property real maxFuel: 0

    // The entity that launched or deployed this one; null for craft. Fuzes
    // ignore anything the owner also owns, the blast spares the owner and a
    // guided seeker sees only what the owner's radar illuminates.
    property Entity owner: null

    // The abilities this entity can invoke, as live slots.
    property list<AbilitySlot> abilities

    // The munition role state; non-null only when this entity is a missile.
    property Weapon weapon: null
}
