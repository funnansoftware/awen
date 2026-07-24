import awen.command

// Ability intent: invokes one of the flown entity's abilities by name —
// launch a weapon, pop a flare. Discrete, so every press posts one record.
Command {
    id: command

    name: Verbs.ability

    // The ability name the record carries.
    property string ability: ""

    function payload(): var {
        return { ability: command.ability };
    }
}
