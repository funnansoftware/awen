import awen.command

// Throttle intent: the flight lever's position, -1 (full brake) to 1 (full
// throttle); the store prices it into the commanded speed fraction.
// Continuous, so re-posts within a frame coalesce to the newest value.
Command {
    id: root

    // The lever position the record carries.
    property real value: 0

    name: Verbs.throttle
    coalesce: true

    function payload(): var {
        return { value: root.value };
    }
}
