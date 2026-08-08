import QtQuick

// Catppuccin Mocha: the pastel dark palette, lavender and mauve where aurora is
// cyan. Every value is a colour from the published Mocha ramp, except the two
// the roles define by construction — the gauge track is the accent at the same
// low alpha aurora uses, and the terrain fill is the rim colour sunk toward
// Crust so a pillar still reads as a rim over a fill.
Theme {
    name: "catppuccin-mocha"
    label: "CATPPUCCIN MOCHA"

    windowBackground: "#1E1E2E" // Base
    panelBackground: "#C7181825" // Mantle, glass over the scope
    instrumentBackground: "#181825" // Mantle
    accent: "#74C7EC" // Sapphire
    accentBright: "#89DCEB" // Sky
    frameInner: "#B4BEFE" // Lavender
    gaugeTrack: "#1A74C7EC" // Sapphire, barely there
    capsTracking: 1
    panelRadius: 2
    textPrimary: "#CDD6F4" // Text
    textHeading: "#BAC2DE" // Subtext1
    textLabel: "#A6ADC8" // Subtext0
    textMuted: "#9399B2" // Overlay2
    textBright: "#F5E0DC" // Rosewater
    warn: "#FAB387" // Peach
    fuel: "#F9E2AF" // Yellow
    damageFill: "#8CF38BA8" // Red, half over the hull beneath
    factionUnknown: "#BAC2DE" // Subtext1
    factionOwnship: "#74C7EC" // Sapphire
    factionFriendly: "#A6E3A1" // Green
    factionNeutral: "#F9E2AF" // Yellow
    factionHostile: "#F38BA8" // Red
    rangeRing: "#585B70" // Surface2
    terrain: "#CBA6F7" // Mauve
    terrainFill: "#362F47" // Mauve sunk toward Crust
    armValid: "#A6E3A1" // Green
    armInvalid: "#FAB387" // Peach
    cursorFree: "#F9E2AF" // Yellow
    cursorLatched: "#89DCEB" // Sky
    detonation: "#F5C2E7" // Pink
    flare: "#FAB387" // Peach
}
