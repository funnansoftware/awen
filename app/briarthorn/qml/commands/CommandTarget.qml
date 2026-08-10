import awen.command

// Designation intent: points the flown craft's guided weapons at one contact
// by track id; an empty contact stands the designation down. Discrete, so
// every pick posts one record.
Command {
    id: root

    // The contact the record carries.
    property string contact: ""

    name: Verbs.target

    function payload(): var {
        return { contact: root.contact };
    }
}
