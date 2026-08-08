import QtMultimedia
import QtQuick

// One cue and the small pool of voices it speaks through.
//
// A SoundEffect is a single voice: play() landing on one that is still sounding
// restarts it from the top, which cuts the waveform mid-flight. That is both
// faults at once — the cue that goes missing when the cursor moves on quickly,
// and the click heard in its place, because an abrupt cut is a step edge like
// any other. Walking a pool instead lets a fast run down a menu overlap its own
// cues, and only a run long enough to use every voice takes one back.
//
// The voices share one decoded sample: QSampleCache keys on the URL, so the
// pool costs four small objects and no extra audio.
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

    // Where the search for a free voice starts, so a pool with every voice busy
    // takes back the one that has been sounding longest rather than the one it
    // just handed out.
    property int turn: 0

    readonly property list<SoundEffect> voices: [
        SoundEffect {
            source: root.source
            volume: root.volume
        },
        SoundEffect {
            source: root.source
            volume: root.volume
        },
        SoundEffect {
            source: root.source
            volume: root.volume
        },
        SoundEffect {
            source: root.source
            volume: root.volume
        }
    ]

    function play() {
        for (let i = 0; i < root.voices.length; ++i) {
            const free = root.voices[(root.turn + i) % root.voices.length];
            if (!free.playing) {
                free.play();
                root.turn = (root.turn + i + 1) % root.voices.length;
                return;
            }
        }
        root.voices[root.turn].play();
        root.turn = (root.turn + 1) % root.voices.length;
    }
}
