import "../themes"

// The corner minimap preset: the same situation display stripped to a clean
// overview — closed rings, a north marker, gutter-clamped contacts and an
// opaque disc masking whatever renders beneath. The armed envelope mirrors
// on with everything else the overview keeps; the cursor does not, because a
// mark drawn this small has no room to stand one off. The caller sizes and
// docks it, and shares the attack scope's projection so the two range
// together.
ViewSituation {
    radiusFraction: 0.45
    symbolSize: height * 0.08
    backgroundColor: Style.theme.windowBackground
    gutterClamp: true
    closedRings: true
    showNorth: true
    showInnerRing: false
    showTicks: false
    showRadarCone: true
    showOwnshipPulse: false
    showTrackLabels: false
    showTrackHealth: false
    showTrackRanges: false
    showEngagements: false
    showTrails: false
}
