import awen.command

// Steer intent: sets the flown entity's steer input, -1 (left) to 1 (right).
// Continuous, so re-posts within a frame coalesce to the newest value.
Command {
    id: root

    // The steer setpoint the record carries.
    property real value: 0

    name: Verbs.steer
    coalesce: true

    function payload(): var {
        return { value: root.value };
    }
}
