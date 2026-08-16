pragma Singleton

import QtQml
import "abilities"

// The ability registry: one definition per file under abilities/, registered
// in the one list below and indexed by the name commands, loadouts and systems
// all route on. Adding an ability is a new file plus a single line here.
QtObject {
    id: root

    // The registration index. Order is not load-bearing.
    readonly property list<Ability> registry: [
        AbilityFlare {},
        AbilityLaunchGuided {},
        AbilityLaunchGun {},
        AbilityLaunchKinetic {}
    ]

    // Name to row, derived from the registry on first lookup.
    readonly property var table: root.indexed(root.registry)

    // The definition routed on a name, or null for an unregistered one.
    function defFor(name: string): Ability {
        const row = root.table[name];
        return row !== undefined ? row : null;
    }

    function indexed(rows: list<Ability>): var {
        const table = {};
        for (let i = 0; i < rows.length; ++i)
            table[rows[i].name] = rows[i];
        return table;
    }
}
