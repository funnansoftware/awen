import QtQml

// A folded input value: every source contributes under its own slot and the
// axis folds them — sum, clamped to the range. Action bindings contribute
// through the router; touch controls and scripts call invoke() directly.
QtObject {
    id: axis

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

    onEnabledChanged: axis.refold()

    // Replaces source's contribution and refolds the value.
    function contribute(source: var, contribution: real) {
        axis.contributions.set(source, contribution);
        axis.refold();
    }

    // Drives the axis directly, no action in between — the path for touch
    // controls, behaviours or scripts.
    function invoke(contribution: real) {
        axis.contribute(axis, contribution);
    }

    // Folds the contributions into the value, unless disabled.
    function refold() {
        if (!axis.enabled)
            return;
        let sum = 0;
        for (const part of axis.contributions.values())
            sum += part;
        axis.value = Math.max(axis.minimum, Math.min(axis.maximum, sum));
    }
}
