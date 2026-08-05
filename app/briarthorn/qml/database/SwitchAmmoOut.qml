// Fires once the launch rack is spent; an unlimited (-1) slot never trips it.
Switch {
    id: root

    function holds(s: var): bool {
        return s.rounds === 0;
    }
}
