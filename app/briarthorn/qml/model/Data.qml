import QtQuick

// One classification's render definition: the symbol outline as unit-box
// points centred on the origin (nose toward -y, coordinates in [-0.5, 0.5]),
// plus the fallback label and the scale the symbol draws at.
QtObject {
    property int classification: Classification.Kind.Unknown
    property list<point> outline
    property string label: ""
    property real symbolScale: 1
}
