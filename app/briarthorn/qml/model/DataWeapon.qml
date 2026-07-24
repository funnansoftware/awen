import QtQml

// One weapon kind's definition row: the munition tuning SystemWeapon reads —
// flight envelope, seeker and warhead — on top of the base render fields.
// All direct game quantities: m/s, deg/s, metres, seconds.
Data {
    // Flight: cruise speed, turn rate at full deflection and the
    // time-of-flight after which the round self-destructs.
    property real speed: 0
    property real turnRate: 0
    property real duration: 0

    // Seeker: a guided round re-homes every tick on the loudest return its
    // owner's radar illuminates, considering returns inside seekerRange.
    property bool guided: false
    property real seekerRange: 0

    // Warhead: the proximity-fuze trigger range, the delay from fuze to
    // detonation and the flat damage applied inside blastRadius.
    property real fuzeRange: 0
    property real fuzeTime: 0
    property real damage: 0
    property real blastRadius: 0
}
