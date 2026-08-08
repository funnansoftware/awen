pragma Singleton

import QtCore
import QtQuick

// The interface's voice: one short cue per navigation event. A singleton
// because a cue outlives the control that fires it: DUEL tears the launch screen
// down inside the very handler that plays the press, and a voice owned by that
// screen would be destroyed mid-sound.
//
// How a cue actually sounds is Cue's business, and which Cue this build got is
// CMake's — the browser is given a silent one, so nothing here imports
// QtMultimedia and nothing above here tests for a platform.
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

    // Whether this build can sound anything: the browser's Cue is a stub, and a
    // settings page that offered a switch there would be offering to silence
    // silence. Read off one cue because all three are the same implementation —
    // which one is arbitrary, that they agree is not.
    readonly property bool available: root.navigateCue.available

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
