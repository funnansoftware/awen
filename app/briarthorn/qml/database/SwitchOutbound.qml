// Fires while a round of the entity's own is still in flight (present), or
// once the sky is clear of them (present false) — the calm side of the same
// test, for the switch back.
Switch {
    id: root

    property bool present: true

    function holds(s: var): bool {
        return root.present ? s.outbound : !s.outbound;
    }
}
