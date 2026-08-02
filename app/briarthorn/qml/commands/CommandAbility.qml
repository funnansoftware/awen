import awen.command

// Ability intent: invokes one of the flown entity's abilities by name —
// launch a weapon, pop a flare. Discrete, so every press posts one record.
Command {
    id: root

    // The ability name the record carries.
    property string ability: ""

    name: Verbs.ability

    function payload(): var {
        return { ability: root.ability };
    }
}
