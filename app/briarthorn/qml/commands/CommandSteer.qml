import awen.command

// Steer intent: sets the flown entity's steer input, -1 (left) to 1 (right).
// Continuous, so re-posts within a frame coalesce to the newest value.
Command {
    id: command

    name: Verbs.steer
    coalesce: true

    // The steer setpoint the record carries.
    property real value: 0

    function payload(): var {
        return { value: command.value };
    }
}
