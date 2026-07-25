import QtQml

// The row shape every database entry satisfies: one classification's render
// definition, as the symbol outline in unit-box points centred on the origin
// (nose toward -y, coordinates in [-0.5, 0.5]), the fallback label and the
// scale the symbol draws at. Instantiated bare it is a presentation-only row a
// sensor plots but nothing ever spawns; spawnable kinds use DataEntity.
QtObject {
    property int classification: Classification.Kind.Unknown
    property list<point> outline
    property string label: ""
    property real symbolScale: 1
}
