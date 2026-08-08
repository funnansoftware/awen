import QtQuick

// One palette: every colour role the chrome draws with, declared once here so a
// theme file is nothing but its own values. Rows live one per file in this
// folder and register in the single list on the Style singleton, so adding a
// palette is a new file and one line — never a switch to keep in step.
//
// Every colour defaults to a sentinel magenta rather than to a real one. A role
// a palette forgets then shows up the first time it is drawn, where inheriting
// another palette's value would hide it and leaving it undeclared would paint
// transparent black. That failure is not hypothetical: the mocha palette
// shipped five verbatim aurora colours.
QtObject {
    id: root

    // The persistence key, fixed for the life of the palette: the player's
    // choice is stored under it, so renaming the file must never change it.
    property string name: ""

    // Player-facing name, as the settings page lists it. A proper noun, so it
    // is not translated.
    property string label: ""

    // What an unfilled role paints — see the note above.
    readonly property color missing: "#FFFF00FF"

    // The window behind everything, the panels laid on it, and the darker wells
    // the instruments draw inside. A panel carries alpha on purpose: the thumb
    // stick, the ability pads and the alert readouts all sit over the live
    // scope, and the tactical picture is meant to show faintly through them.
    property color windowBackground: root.missing
    property color panelBackground: root.missing
    property color instrumentBackground: root.missing

    // The interface's own colour: accent carries every live line and border,
    // accentBright the lit state of one under a cursor or a thumb.
    property color accent: root.missing
    property color accentBright: root.missing

    // The hairline that frames panels and separates bands.
    property color frameInner: root.missing

    // The unfilled part of a gauge, behind its arc.
    property color gaugeTrack: root.missing

    // Tracking on the bold uppercase chrome — labels, units and the page's
    // own actions. One role, so one number rather than one per caption.
    property real capsTracking: 1

    // The corner radius every panel and cap draws with.
    property int panelRadius: 2

    // The type ramp: primary reads a value, heading titles a page, label
    // captions one, muted says it is off or absent, bright is the one thing on
    // screen being shouted.
    property color textPrimary: root.missing
    property color textHeading: root.missing
    property color textLabel: root.missing
    property color textMuted: root.missing
    property color textBright: root.missing

    // The alarm colour, and the fuel arc that is not quite one.
    property color warn: root.missing
    property color fuel: root.missing

    // Damage taken, over the hull that is left.
    property color damageFill: root.missing

    // Allegiance, as the scope plots it.
    property color factionUnknown: root.missing
    property color factionOwnship: root.missing
    property color factionFriendly: root.missing
    property color factionNeutral: root.missing
    property color factionHostile: root.missing

    // The scope's range rings.
    property color rangeRing: root.missing

    // Arena terrain: a bright rim over a dark fill — earthy against the
    // instrument lines, and dimmer than warn so a pillar never reads as an
    // alert.
    property color terrain: root.missing
    property color terrainFill: root.missing

    // Launch authority: the armed weapon's envelope, its lock bracket and the
    // rack's own state all read valid the moment the shot would fire, and
    // invalid — the colour a refused control flashes — while it would not.
    // Kept off the faction palette: this is the pilot's own weapon answering,
    // not a contact's allegiance.
    property color armValid: root.missing
    property color armInvalid: root.missing

    // The seeker cursor, hunting and then holding what it found.
    property color cursorFree: root.missing
    property color cursorLatched: root.missing

    // A round going off, and a decoy burning.
    property color detonation: root.missing
    property color flare: root.missing
}
