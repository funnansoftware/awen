pragma Singleton

import QtQml

// The behaviour vocabulary: every personality, maneuver and stance name
// written once, referenced everywhere a definition, registry or spawn site
// would otherwise retype the string. Grouped by family — typed groups, so
// the linter vouches for every reference — because families may share a
// word (the evade stance and the evade maneuver).
QtObject {
    id: root

    // The personality names spawn sites and kind rows route on.
    component PersonalityNames: QtObject {
        readonly property string aggressive: "aggressive"
        readonly property string defensive: "defensive"
        readonly property string duelist: "duelist"
        readonly property string fearful: "fearful"
        readonly property string tactical: "tactical"
    }

    // The maneuver names stances fly — the keys of the model's Maneuvers
    // factory table.
    component ManeuverNames: QtObject {
        readonly property string crank: "crank"
        readonly property string evade: "evade"
        readonly property string flee: "flee"
        readonly property string formation: "formation"
        readonly property string notch: "notch"
        readonly property string orbit: "orbit"
        readonly property string pursue: "pursue"
    }

    // The stance names personalities switch between.
    component StanceNames: QtObject {
        readonly property string abscond: "abscond"
        readonly property string advance: "advance"
        readonly property string bail: "bail"
        readonly property string crank: "crank"
        readonly property string defend: "defend"
        readonly property string depart: "depart"
        readonly property string disengage: "disengage"
        readonly property string evade: "evade"
        readonly property string guard: "guard"
        readonly property string monitor: "monitor"
        readonly property string press: "press"
        readonly property string repel: "repel"
        readonly property string retire: "retire"
        readonly property string shadow: "shadow"
        readonly property string snipe: "snipe"
        readonly property string strike: "strike"
        readonly property string withdraw: "withdraw"
    }

    readonly property PersonalityNames personality: PersonalityNames {}
    readonly property ManeuverNames maneuver: ManeuverNames {}
    readonly property StanceNames stance: StanceNames {}
}
