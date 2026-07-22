import QtQml

// One store-side registration: the record name this handler consumes and,
// via onHandle, the transition it applies to the store's model. Declared as
// a child of a Store — adding a verb adds a handler, never branching.
QtObject {
    // The record name routed here.
    required property string name

    // Skipped by the store's router while false.
    property bool enabled: true

    // Fired with the consumed record's payload.
    signal handle(payload: var)
}
