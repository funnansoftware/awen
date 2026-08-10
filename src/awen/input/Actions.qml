import QtQml

// Routes raw input events to a declared set of actions: each event fans out
// to every action — several may share one input — and the return reports
// whether any of them consumed it. The app forwards key and gamepad events
// here once, and the bound axes move.
QtObject {
    id: root

    // The action bindings, as child objects.
    default property list<Action> actions

    function keyPressed(key: int): bool {
        return root.fan(action => action.keyPressed(key));
    }
    function keyReleased(key: int): bool {
        return root.fan(action => action.keyReleased(key));
    }
    function buttonPressed(button: int): bool {
        return root.fan(action => action.buttonPressed(button));
    }
    function buttonReleased(button: int): bool {
        return root.fan(action => action.buttonReleased(button));
    }
    function axisMoved(axis: int, position: real): bool {
        return root.fan(action => action.axisMoved(axis, position));
    }

    // Returns every action to rest — call on focus loss, where key releases
    // are never delivered and held state would otherwise stick.
    function reset() {
        for (let i = 0; i < root.actions.length; ++i) {
            const action = root.actions[i];
            if (action !== null)
                action.reset();
        }
    }

    // Has every action re-state what its source is saying now — call after a
    // reset() that was a handover rather than a departure, where the router
    // goes on listening. The digital bindings stay at rest, since a release
    // that never arrived cannot be read back; the analogue ones re-report
    // themselves, since a control the player is still holding is not at rest
    // however long it has been silent.
    function resync() {
        for (let i = 0; i < root.actions.length; ++i) {
            const action = root.actions[i];
            if (action !== null)
                action.resync();
        }
    }

    // Delivers one event to every action without short-circuiting, so shared
    // inputs reach every binding. A destroyed action leaves a null slot behind,
    // and skipping it keeps one dead binding from taking the router down.
    function fan(deliver: var): bool {
        let consumed = false;
        for (let i = 0; i < root.actions.length; ++i) {
            const action = root.actions[i];
            if (action !== null)
                consumed = deliver(action) || consumed;
        }
        return consumed;
    }
}
