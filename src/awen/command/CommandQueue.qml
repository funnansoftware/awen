import awen.entity

// The command bus: every state-changing intent crosses the game as a plain
// {name, payload} record posted here — from typed emitters, input handlers,
// AI, tests or (later) a network peer alike. A System: declare it first in
// the Systems list, and its tick publishes the batch the stores after it
// consume. Posts made during a tick land next tick by construction.
System {
    id: queue

    // The batch published at the last tick, records in post order; stores
    // drain this from their update(). Treat both buffers as queue-internal.
    property var commands: []

    // Records accumulated since the last tick, awaiting publication.
    property var pending: []

    // Records of the last published batch no store consumed — nonzero means
    // a posted name has no handler anywhere.
    property int unconsumed: 0

    // Names already warned about, so an unhandled name reports once.
    property var warned: new Set()

    // Posts one record; the payload is frozen so every observer reads the
    // same snapshot. A coalescing poster passes itself as key: its pending
    // record's payload is replaced in place, keeping the original queue slot.
    function post(name: string, payload: var, key: var) {
        const frozen = Object.freeze(payload || ({}));
        for (let i = 0; key && i < queue.pending.length; ++i) {
            if (queue.pending[i].key === key) {
                queue.pending[i].payload = frozen;
                return;
            }
        }
        queue.pending.push({ name: name, payload: frozen, key: key || null, consumed: false });
    }

    // The tick: accounts for the outgoing batch's unconsumed records — a
    // typo'd or unwired name warns once — then publishes the pending batch.
    function update(dt: real) {
        let missed = 0;
        for (let i = 0; i < queue.commands.length; ++i) {
            const record = queue.commands[i];
            if (record.consumed)
                continue;
            ++missed;
            if (!queue.warned.has(record.name)) {
                queue.warned.add(record.name);
                console.warn("CommandQueue: no store consumed \"" + record.name + "\"");
            }
        }
        queue.unconsumed = missed;
        queue.commands = queue.pending;
        queue.pending = [];
    }

    // Drops pending and published records — call on scenario reset so a
    // paused game does not apply stale intents on resume.
    function clear() {
        queue.pending = [];
        queue.commands = [];
    }
}
