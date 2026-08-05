import QtQml

// One temperament: a named machine of stances, entry stance first.
// Personality-wide switches are checked before the current stance's, and a
// hit naming the current stance simply holds there.
QtObject {
    id: root

    // The name spawn sites and kind rows route on.
    property string name: ""

    property list<Stance> stances
    property list<Switch> switches

    // Name to stance, derived from the list on first lookup.
    readonly property var table: root.indexed(root.stances)

    // The stance routed on a name, or null for one the personality lacks.
    function stanceFor(name: string): Stance {
        const row = root.table[name];
        return row !== undefined ? row : null;
    }

    function indexed(rows: list<Stance>): var {
        const table = {};
        for (let i = 0; i < rows.length; ++i)
            table[rows[i].name] = rows[i];
        return table;
    }
}
