import QtQml

// The row shape every database entry satisfies: one classification's render
// definition, as the symbol outline in unit-box points centred on the origin
// (nose toward -y, coordinates in [-0.5, 0.5]), the fallback label, the scale
// the symbol draws at and whether the mark carries a hull gauge alongside it.
// Instantiated bare it is a presentation-only row a
// sensor plots but nothing ever spawns; spawnable kinds use DataEntity.
QtObject {
    id: root

    property int classification: Classification.Kind.Unknown
    property list<point> outline
    property string label: ""
    property real symbolScale: 1

    // Whether a resolved mark of this kind carries a hull gauge on its left.
    // An airframe's condition is worth reading straight off the picture; a
    // round in flight, a lure and an unresolved return all plot bare.
    property bool hullGauge: false

    // Whether a resolved mark of this kind carries its contact label. A
    // cannon stream would caption every tracer in it; a round that small
    // plots as a bare streak instead.
    property bool trackLabel: true
}
