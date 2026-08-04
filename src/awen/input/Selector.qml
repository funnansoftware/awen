import QtQml

// A discrete selection cursor for button menus: keys and pad edges move it
// over count ordered items and activate() fires the chosen one. The highlight
// only engages once the player actually navigates — a mouse-only user never
// sees a forced selection — and until then activate() fires the declared
// primary item.
QtObject {
    id: root

    // How many items the menu declares; index stays clamped inside it.
    property int count: 0

    // The item activate() fires before the player has navigated — by default
    // the first, but a menu whose confirm is not its top entry points it there.
    property int primary: 0

    // The selected item. move() owns the writes.
    property int index: 0

    // Whether the player has navigated yet — gates the visual highlight.
    property bool engaged: false

    // The chosen item, fired by activate().
    signal activated(int index)

    onCountChanged: {
        if (root.index >= root.count)
            root.index = Math.max(0, root.count - 1);
    }

    // Moves the cursor by delta, clamped at the ends, engaging the highlight.
    function move(delta: int) {
        if (root.count === 0)
            return;
        root.index = Math.max(0, Math.min(root.count - 1, root.index + delta));
        root.engaged = true;
    }

    // Fires the selected item — the primary until the player has navigated.
    function activate() {
        const chosen = root.engaged ? root.index : root.primary;
        if (chosen >= 0 && chosen < root.count)
            root.activated(chosen);
    }

    // Returns the cursor to the top, disengaged — for a menu being (re)shown.
    function reset() {
        root.index = 0;
        root.engaged = false;
    }
}
