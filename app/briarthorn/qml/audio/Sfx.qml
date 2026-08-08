pragma Singleton

import QtCore
import QtMultimedia
import QtQuick

// The interface's voice: one short cue per navigation event, played through
// SoundEffect because a menu tick has to land on the frame that caused it —
// MediaPlayer decodes first and arrives a beat late. A singleton because a cue
// outlives the control that fires it: DUEL tears the launch screen down inside
// the very handler that plays the press, and an effect owned by that screen
// would be destroyed mid-sound.
//
// The cues are Kenney's CC0 interface pack, renamed to the role each one plays;
// see ../../assets/audio/README.md, which is also where the reason they are
// 48 kHz stereo lives. They carry their own volumes, because the three fire at
// very different rates — navigate on every step through a menu — and those three
// numbers are the whole mix.
QtObject {
    id: root

    // The on-disk copy. Declared before enabled, whose initialiser reads it —
    // that order is load-bearing, exactly as it is on Style.
    readonly property Settings store: Settings {
        category: "audio"
    }

    // Whether the interface speaks at all. Written through setEnabled(), never
    // assigned: a bare assignment applies and is then forgotten on quit.
    //
    // Compared as text rather than assigned straight across, because the store
    // hands a boolean back the way its backend kept it — the windows registry
    // returns the string "false", and every non-empty string is true the moment
    // QML coerces one into a bool. Read directly, the switch could be turned off
    // but never came back off.
    property bool enabled: String(root.store.value("enabled", true)) !== "false"

    // The cursor arriving on an item, by highlight or by hover.
    readonly property Cue navigateCue: Cue {
        source: "qrc:/audio/navigate.wav"
        volume: 0.3
    }

    // An item being chosen.
    readonly property Cue pressCue: Cue {
        source: "qrc:/audio/press.wav"
        volume: 0.5
    }

    // A page being backed out of.
    readonly property Cue backCue: Cue {
        source: "qrc:/audio/back.wav"
        volume: 0.45
    }

    // One cue and the small pool of voices it speaks through.
    //
    // A SoundEffect is a single voice: play() landing on one that is still
    // sounding restarts it from the top, which cuts the waveform mid-flight.
    // That is both faults at once — the cue that went missing when the cursor
    // moved on quickly, and the click heard in its place, because an abrupt cut
    // is a step edge like any other. Walking a pool instead lets a fast run down
    // a menu overlap its own cues, and only a run long enough to use every voice
    // takes one back.
    //
    // The voices share one decoded sample: QSampleCache keys on the URL, so the
    // pool costs four small objects and no extra audio.
    component Cue: QtObject {
        id: cue

        required property url source
        property real volume: 1

        // Where the search for a free voice starts, so a busy pool hands out
        // the voice that has been sounding longest rather than the same one.
        property int turn: 0

        readonly property list<SoundEffect> voices: [
            SoundEffect {
                source: cue.source
                volume: cue.volume
            },
            SoundEffect {
                source: cue.source
                volume: cue.volume
            },
            SoundEffect {
                source: cue.source
                volume: cue.volume
            },
            SoundEffect {
                source: cue.source
                volume: cue.volume
            }
        ]

        function play() {
            for (let i = 0; i < cue.voices.length; ++i) {
                const free = cue.voices[(cue.turn + i) % cue.voices.length];
                if (!free.playing) {
                    free.play();
                    cue.turn = (cue.turn + i + 1) % cue.voices.length;
                    return;
                }
            }
            cue.voices[cue.turn].play();
            cue.turn = (cue.turn + 1) % cue.voices.length;
        }
    }

    function navigate() {
        if (root.enabled)
            root.navigateCue.play();
    }

    function press() {
        if (root.enabled)
            root.pressCue.play();
    }

    function back() {
        if (root.enabled)
            root.backCue.play();
    }

    // Puts the choice in force and remembers it, as Style.select() does —
    // written through at once and synced, because a web build's tab can close
    // without ever running a destructor.
    function setEnabled(on: bool) {
        root.enabled = on;
        root.store.setValue("enabled", on);
        root.store.sync();
    }

    // Empty on purpose: the call is the point. A QML singleton is built on
    // first use and a SoundEffect loads its source asynchronously, so without
    // someone touching this at startup the first cue of the session is the one
    // that gets dropped — still Loading when play() reaches it.
    function warm() {
    }
}
