import QtQml

// The six ratings that say what an entity is capable of, each 0..10 (see
// GameRules.maxStat). Dimensionless on purpose: a definition rates an airframe
// and GameRules decides what that rating is worth in m/s, metres or hit
// points, so retuning the game never means editing the roster.
QtObject {
    id: root

    // Full-throttle speed, and the fuel burn that comes with holding it.
    property real kinetic: 0

    // Turn rate at full deflection, and the acceleration behind it.
    property real maneuver: 0

    // Hull integrity and fuel capacity.
    property real durable: 0

    // A guided seeker's acquisition range.
    property real compute: 0

    // Radar detection range.
    property real sensor: 0

    // Emission signature — lower is louder, and a guided seeker homes on the
    // loudest illuminated return.
    property real stealth: 0
}
