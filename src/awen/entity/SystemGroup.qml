import QtQml

// A System composed of child systems, ticked in declaration order — one
// swappable slot in a Systems run for a whole unit of behaviour, such as a
// level or a mode. Disabling the group skips every child.
System {
    id: root

    // The grouped systems, in run order; child System objects land here.
    default property list<System> systems

    function update(dt: real) {
        for (let i = 0; i < root.systems.length; ++i) {
            const system = root.systems[i];
            if (system.enabled)
                system.update(dt);
        }
    }
}
