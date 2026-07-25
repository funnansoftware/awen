pragma Singleton

import QtQml
import "entities"
import "weapons"

// THE game database: every static kind definition, looked up by
// classification. The rows live one per file under entities/ and weapons/ and
// register in the one list below; the lookup table derives from it, so adding
// a kind is a new file, a new Classification and a single line here — never a
// switch to keep in step.
QtObject {
    id: database

    // The registration index. Order is not load-bearing.
    readonly property list<Data> registry: [
        // Perception-only rows, never spawned.
        DataUnknown {},
        // Spawnable craft.
        DataAircraftFighter {},
        DataDecoy {},
        // Munitions.
        DataMissileGuided {},
        DataMissileKinetic {}
    ]

    // Classification to row, derived from the registry on first lookup.
    readonly property var table: database.indexed(database.registry)

    // The row for a classification; the unknown-contact row for anything
    // missing, so a render lookup always has something to draw.
    function dataFor(classification: int): Data {
        const row = database.table[classification];
        return row !== undefined ? row : database.table[Classification.Kind.Unknown];
    }

    // The spawnable row, or null — the type check is the spawnability check,
    // so a presentation-only row simply fails it.
    function entityDataFor(classification: int): DataEntity {
        const row = database.table[classification];
        return row instanceof DataEntity ? row : null;
    }

    // The munition row behind a launchable classification, or null.
    function weaponDataFor(classification: int): DataWeapon {
        const row = database.table[classification];
        return row instanceof DataWeapon ? row : null;
    }

    function indexed(rows: list<Data>): var {
        const table = {};
        for (let i = 0; i < rows.length; ++i)
            table[rows[i].classification] = rows[i];
        return table;
    }
}
