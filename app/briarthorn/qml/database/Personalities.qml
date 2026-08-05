pragma Singleton

import QtQml
import "personalities"

// The personality registry: one definition per file under personalities/,
// registered in the one list below and indexed by the name spawn sites and
// kind rows route on. Adding a personality is a new file plus a single line.
QtObject {
    id: root

    // The registration index. Order is not load-bearing.
    readonly property list<Personality> registry: [
        PersonalityAggressive {},
        PersonalityDefensive {},
        PersonalityFearful {},
        PersonalityTactical {}
    ]

    // Name to row, derived from the registry on first lookup.
    readonly property var table: root.indexed(root.registry)

    // The definition routed on a name, or null for an unregistered one.
    function defFor(name: string): Personality {
        const row = root.table[name];
        return row !== undefined ? row : null;
    }

    function indexed(rows: list<Personality>): var {
        const table = {};
        for (let i = 0; i < rows.length; ++i)
            table[rows[i].name] = rows[i];
        return table;
    }
}
