import QtQml

// One munition kind: a DataEntity, because a round in flight is a real world
// object, plus the combat tuning SystemWeapon reads. Its flight comes out of
// the stats — kinetic sets speed, maneuver the turn rate, compute the seeker's
// reach — so only the motor, the fuze and the warhead are spelled out here.
DataEntity {
    id: root

    // Multiplier on the speed the kinetic rating affords, so a motor can push
    // the round past the airframe ceiling (GameRules.maxSpeed).
    property real speedMultiplier: 1

    // Seconds of flight after which the round self-destructs.
    property real duration: 0

    // A guided round re-homes every tick on the loudest return its owner's
    // radar illuminates, considering returns inside seekerRange.
    property bool guided: false

    // Warhead: the proximity-fuze trigger range, the delay from fuze to
    // detonation and the flat damage applied inside blastRadius.
    property real fuzeRange: 0
    property real fuzeTime: 0
    property real damage: 0
    property real blastRadius: 0

    // Flight speed off the rail, m/s.
    readonly property real speed: GameRules.topSpeedFor(stats.kinetic) * speedMultiplier

    // The seeker's acquisition range, metres; a dumb round has none.
    readonly property real seekerRange: guided ? GameRules.guidedRangeFor(stats.compute) : 0

    // How far the round can physically fly. The one definition of a shot
    // envelope — SystemEngage fires inside it rather than carrying its own
    // range number.
    readonly property real reach: speed * duration
}
