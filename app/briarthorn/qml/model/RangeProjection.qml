import QtQml

// View state for how the scope projects the track picture onto the range
// rings: the selectable range steps and the world-to-screen (metres to
// pixels) scale they imply. Display-only — this never touches the sim.
QtObject {
    id: projection

    // The selectable steps as the outer ring's span in metres, innermost
    // first; the inner ring always sits at half the outer.
    readonly property list<real> steps: [20000, 40000, 80000, 160000]

    // Highest step the current radar can reach, and the selected step
    // (clamped on read, so an out-of-range selection stays harmless).
    property int maxStep: steps.length - 1
    property int step: maxStep

    readonly property int clampedStep: Math.max(0, Math.min(step, maxStep))

    // The active step's ring spans, metres.
    readonly property real range: steps[clampedStep]
    readonly property real innerRange: range / 2

    readonly property real rangeKm: range / 1000
    readonly property real innerRangeKm: innerRange / 1000

    // World metres to screen pixels for a scope whose outer ring is drawn
    // edgePx from the centre.
    function pixelsPerMeter(edgePx: real): real {
        return projection.range > 0 ? edgePx / projection.range : 0;
    }

    // Range in: a shorter span, so contacts plot further out. Clamped.
    function rangeIn() {
        projection.step = Math.max(0, projection.clampedStep - 1);
    }

    // Range out: a longer span, so contacts plot closer in. Clamped.
    function rangeOut() {
        projection.step = Math.min(projection.maxStep, projection.clampedStep + 1);
    }
}
