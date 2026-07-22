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
        for (let i = 0; i < root.actions.length; ++i)
            root.actions[i].reset();
    }

    // Delivers one event to every action without short-circuiting, so shared
    // inputs reach every binding.
    function fan(deliver: var): bool {
        let consumed = false;
        for (let i = 0; i < root.actions.length; ++i)
            consumed = deliver(root.actions[i]) || consumed;
        return consumed;
    }
}
