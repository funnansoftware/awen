import QtQml

// A spawnable kind: the render row plus the type-level state an Entity takes
// its defaults from. What the airframe can actually do is not written here —
// the stats rate it and GameRules prices the ratings, so one row describes a
// craft in the same terms whatever the game's tuning happens to be.
Data {
    // The kind's ratings. A spawn site overrides individual ones to make its
    // instance better or worse than stock.
    property Stats stats: Stats {}

    // The radar's total field-of-view cone in degrees, centred on heading;
    // 360 is an all-round sensor.
    property real radarFov: 360

    // The abilities instances carry, by registry name — the whole loadout an
    // airframe brings, turned into live AbilitySlots when one is created.
    property list<string> abilities
}
