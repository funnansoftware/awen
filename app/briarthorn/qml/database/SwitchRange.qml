// Fires on the engage target sitting inside (or outside) a fraction of a
// priced envelope; never with no target, or against an envelope that prices
// to nothing.
Switch {
    id: root

    property bool inside: true

    // The band edge, as a fraction of the envelope named below.
    property real at: 1
    property int of: Envelope.Kind.OwnWeapon

    function holds(s: var): bool {
        if (s.target === null)
            return false;
        const span = root.of === Envelope.Kind.OwnWeapon ? s.reach : root.of === Envelope.Kind.TargetWeapon ? s.targetReach : s.entity.detectionRange;
        if (span <= 0)
            return false;
        return root.inside ? s.range <= root.at * span : s.range > root.at * span;
    }
}
