import QtQml

// A folded input value: every source contributes under its own slot and the
// axis folds them — sum, clamped to the range. Action bindings contribute
// through the router; touch controls and scripts call invoke() directly.
QtObject {
    id: root

    // While false the fold is frozen: contributions keep recording, and the
    // value snaps back to the live input state on re-enable.
    property bool enabled: true

    // The clamp range the folded value is kept inside.
    property real minimum: -1
    property real maximum: 1

    // The current folded value; refold() owns the writes. Assignments of an
    // unchanged fold do not notify, so valueChanged fires once per real move.
    property real value: 0

    // One contribution per source, keyed by the source object itself.
    property var contributions: new Map()

    onEnabledChanged: root.refold()

    // Replaces source's contribution and refolds the value.
    function contribute(source: var, contribution: real) {
        root.contributions.set(source, contribution);
        root.refold();
    }

    // Drives the axis directly, no action in between — the path for touch
    // controls, behaviours or scripts.
    function invoke(contribution: real) {
        root.contribute(root, contribution);
    }

    // Folds the contributions into the value, unless disabled.
    function refold() {
        if (!root.enabled)
            return;
        let sum = 0;
        for (const part of root.contributions.values())
            sum += part;
        root.value = Math.max(root.minimum, Math.min(root.maximum, sum));
    }
}
