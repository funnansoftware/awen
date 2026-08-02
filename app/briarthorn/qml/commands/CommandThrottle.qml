import awen.command

// Throttle intent: sets the flown entity's throttle input, 0 to 1.
// Continuous, so re-posts within a frame coalesce to the newest value.
Command {
    id: root

    // The throttle setpoint the record carries.
    property real value: 0

    name: Verbs.throttle
    coalesce: true

    function payload(): var {
        return { value: root.value };
    }
}
