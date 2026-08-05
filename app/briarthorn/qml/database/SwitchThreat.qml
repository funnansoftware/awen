// Fires while a homing round is marked inbound inside a fraction of the
// defended craft's detection envelope (present), or once none is (present
// false) — the calm side of the same test, for the switch back.
Switch {
    id: root

    property bool present: true

    // Fraction of the carrier's detection range the round must close inside.
    property real within: 1

    function holds(s: var): bool {
        const inbound = s.threat !== null && s.threatRange <= root.within * s.entity.detectionRange;
        return root.present ? inbound : !inbound;
    }
}
