import QtMultimedia
import QtQuick

// One cue, and the one voice it speaks through.
//
// A single SoundEffect per cue, deliberately. The expensive thing here is not
// the sample, it is the audio device: Qt probes the sink's supported formats on
// an effect's FIRST play — dozens of IsFormatSupported calls, on the main
// thread — and on a USB interface that burst is long enough to chop the very
// sound that triggered it. A pool of voices multiplies that cost by its size
// and buys almost nothing back, because these cues are 10-70 ms and a player
// cannot navigate fast enough to overlap one with itself.
//
// warm() is what pays the cost, once, at startup and in silence. Without it the
// player pays it instead, spread across their first few keypresses — which is
// heard as cues that cut out, crackle, or go missing, and then settle.
//
// This is the QtMultimedia implementation. wasm/Cue.qml is the silent one the
// browser build is given instead, under this same type name — so Sfx, and every
// caller above it, knows about neither. See CMakeLists.txt.
QtObject {
    id: root

    required property url source
    property real volume: 1

    // Whether this build can sound anything at all. The settings page reads it
    // through Sfx, so it offers an audio switch only where there is audio.
    readonly property bool available: true

    readonly property SoundEffect voice: SoundEffect {
        source: root.source
        volume: root.volume

        // The warming play is the only muted one, and it unmutes itself the
        // moment it is over. Hung off playing rather than a timer because a
        // QML Timer rides the animation driver, which an occluded window
        // stops — and a cue that stayed muted would be worse than the glitch
        // this avoids.
        onPlayingChanged: if (!playing && muted)
            muted = false
    }

    // Retriggering restarts the voice. At these lengths that is what should
    // happen: one cursor tick is audible at a time, and a restart the player
    // is fast enough to cause is one they asked for.
    function play() {
        root.voice.play();
    }

    // Opens the device and pays for the format probe now, silently, so the
    // first cue the player actually asks for is not the one that pays.
    function warm() {
        root.voice.muted = true;
        root.voice.play();
    }
}
