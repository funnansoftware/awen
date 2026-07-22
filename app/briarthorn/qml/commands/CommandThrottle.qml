import awen.command

// Throttle intent: sets the flown entity's throttle input, 0 to 1.
// Continuous, so re-posts within a frame coalesce to the newest value.
Command {
    id: command

    name: Verbs.throttle
    coalesce: true

    // The throttle setpoint the record carries.
    property real value: 0

    function payload(): var {
        return { value: command.value };
    }
}
