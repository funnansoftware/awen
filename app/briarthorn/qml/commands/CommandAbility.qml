import awen.command

// Ability intent: invokes one of the flown entity's abilities by name —
// launch a weapon, pop a flare. Discrete presses post one record each;
// automatic abilities post the falling edge too, as active false, so the
// store can stand a held trigger back down.
Command {
    id: root

    // The ability name the record carries.
    property string ability: ""

    name: Verbs.ability

    function payload(): var {
        return { ability: root.ability, active: true };
    }
}
