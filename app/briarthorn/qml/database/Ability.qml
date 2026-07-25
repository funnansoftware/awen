import QtQml

// Base definition row for one ability an entity can invoke: identity plus the
// cooldown and charge tuning shared by every carrier. One instance per kind
// lives in the Abilities registry; live per-entity state lives on an
// AbilitySlot referencing the row.
QtObject {
    // The name ability commands, loadouts and systems all route on.
    property string name: ""

    // Player-facing label.
    property string label: ""

    // Seconds between invocations; 0 gates on charges alone.
    property real cooldown: 0

    // Rounds a fresh slot carries; -1 is unlimited.
    property int charges: -1

    // The controls this ability ships bound to: a Qt.Key code and an
    // awen.gamepad Gamepad.Button code, -1 for unbound. The keymap seeds from
    // these, so arming a new ability needs no entry in a binding table.
    property int defaultKey: -1
    property int defaultButton: -1
}
