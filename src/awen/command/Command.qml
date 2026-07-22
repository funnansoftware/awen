import QtQml

// Optional typed emitter for one verb over the record protocol: declare the
// payload as properties, override payload() to snapshot them, and call
// post() when the intent fires. Raw queue.post(name, payload) records are
// equivalent on the bus — emitters just add standing bindings, snapshot
// discipline and coalescing.
QtObject {
    id: command

    // The queue this verb posts to.
    required property CommandQueue queue

    // The record name stores route on.
    required property string name

    // post() is a no-op while false.
    property bool enabled: true

    // While true at most one record from this instance is pending at a time,
    // the newest payload replacing it in place — for continuous verbs.
    property bool coalesce: false

    // Override: snapshot the verb's payload properties into a plain object.
    // Payloads carry plain data — ids and numbers, never object references.
    function payload(): var {
        return ({});
    }

    // Snapshots the payload, merges per-post overrides on top, and posts.
    function post(overrides: var) {
        if (command.enabled)
            command.queue.post(command.name, Object.assign(command.payload(), overrides || {}), command.coalesce ? command : null);
    }
}
