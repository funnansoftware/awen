import QtQml

// Base definition row for one ability an entity can invoke: identity plus the
// cooldown and charge tuning shared by every carrier. One instance per kind
// lives in the Abilities registry; live per-entity state lives on an
// AbilitySlot referencing the row.
QtObject {
    id: root

    // The name ability commands, loadouts and systems all route on.
    property string name: ""

    // Player-facing label.
    property string label: ""

    // Seconds between invocations; 0 gates on charges alone.
    property real cooldown: 0

    // Rounds a fresh slot carries; -1 is unlimited.
    property int charges: -1

    // Whether the trigger is a hold rather than a press: an automatic slot
    // fires every time its cooldown allows while the trigger is down, and
    // never arms — letting go is the only way to stop it.
    property bool automatic: false

    // The controls this ability ships bound to: a Qt.Key code and an
    // awen.gamepad Gamepad.Button code, -1 for unbound. The keymap seeds from
    // these, so arming a new ability needs no entry in a binding table.
    property int defaultKey: -1
    property int defaultButton: -1

    // Where this ability's stores sit on the carrier's silhouette, in the
    // same unit-box frame the silhouette is drawn in — one point per station
    // glyph on the stores page; empty draws none. Visual metadata like the
    // default controls, never a stat.
    property list<point> stations

    // What one of those stations holds, as the classification whose outline
    // the stores page draws the station with — the round a rack launches, the
    // decoy a pod pops. Each family binds it from the kind it already names,
    // so the page never asks what sort of ability it is drawing.
    property int stationKind: Classification.Kind.Unknown
}
