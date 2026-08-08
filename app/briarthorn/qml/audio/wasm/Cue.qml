import QtQuick

// The browser's cue: the same shape as ../Cue.qml and silent.
//
// Qt ships QtMultimedia for the multithreaded wasm kit only, and briarthorn's
// web build is single-threaded on purpose — multithreaded wasm needs
// SharedArrayBuffer, which means COOP/COEP headers on the host and no
// cross-origin embedding of the app. So the browser gets no audio rather than a
// different threading model, and it gets it as a stub rather than as a guard at
// every call site: an `import QtMultimedia` that resolves to nothing does not
// degrade, it stops Main.qml loading.
//
// available is what tells the settings page not to offer a switch for sound
// that cannot play.
QtObject {
    id: root

    required property url source
    property real volume: 1

    readonly property bool available: false

    function play() {
    }
}
