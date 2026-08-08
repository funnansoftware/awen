import QtQuick

QtObject {
    id: root

    property color windowBackground: "#1e1e2e"
    property color panelBackground: "#181825"
    property color instrumentBackground: "#181825"
    property color accent: "#74c7ec"
    property color accentBright: "#89dceb"
    property color frameInner: "#b4befe"
    property color gaugeTrack: "#1A66E6FF"
    // Tracking on the bold uppercase chrome — labels, units and the page's
    // own actions. One role, so one number rather than one per caption.
    property real capsTracking: 1
    property int panelRadius: 2
    property color textPrimary: "#cdd6f4"
    property color textHeading: "#bac2de"
    property color textLabel: "#a6adc8"
    property color textMuted: "#9399b2"
    property color textBright: "#f5e0dc"
    property color warn: "#fab387"
    property color fuel: "#f9e2af"
    property color damageFill: "#f38ba8"
    property color factionUnknown: "#bac2de"
    property color factionOwnship: "#74c7ec"
    property color factionFriendly: "#a6e3a1"
    property color factionNeutral: "#f9e2af"
    property color factionHostile: "#f38ba8"
    property color rangeRing: "#FF11566A"
    // Arena terrain: a burnt-orange rim over a dark leather fill — earthy
    // against the cyan instrument lines, and dimmer than warn so a pillar
    // never reads as an alert.
    property color terrain: "#cba6f7"
    property color terrainFill: "#cba6f7"
    // Launch authority: the armed weapon's envelope, its lock bracket and the
    // rack's own state all read valid the moment the shot would fire, and
    // invalid — the colour a refused control flashes — while it would not.
    // Kept off the faction palette: this is the pilot's own weapon answering,
    // not a contact's allegiance.
    property color armValid: "#a6e3a1"
    property color armInvalid: "#fab387"
    property color cursorFree: "#FFFFC23D"
    property color cursorLatched: "#FF6CFBFF"
    property color detonation: "#FFFF6FA8"
    property color flare: "#fab387"
}
