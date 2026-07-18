import QtQml

// Base type for a game system: derive in QML and override update() to act on
// game state each tick. On its own a System does nothing — a Systems runner
// drives the calls.
QtObject {
    // Skipped by the Systems runner while false.
    property bool enabled: true

    // Called by the Systems runner each tick; dt is the frame time in seconds.
    function update(dt: real) {
    }
}
