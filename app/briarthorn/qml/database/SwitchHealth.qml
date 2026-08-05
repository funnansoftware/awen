// Fires at or under a hull fraction.
Switch {
    id: root

    property real below: 0.3

    function holds(s: var): bool {
        return s.healthFrac <= root.below;
    }
}
