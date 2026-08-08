// Fires while a hostile round is riding a decoy of the entity's own — the
// window a pop bought, and the only time flying off the flare is what
// matters (present) — or once none is on one (present false), the calm side
// of the same test for the switch back.
Switch {
    id: root

    property bool present: true

    function holds(s: var): bool {
        return root.present ? s.decoy !== null : s.decoy === null;
    }
}
