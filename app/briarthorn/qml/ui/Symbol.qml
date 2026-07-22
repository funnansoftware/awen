import QtQuick
import awen.shapes
import "../model"
import "../themes"

// A scope symbol drawn in screen space: the classification's outline polygon
// coloured by side, nose turned to noseAngle, with an upright label below.
// Centre it on the plot point; an empty label falls back to the
// classification's.
Item {
    id: symbol

    property int classification: Classification.Kind.Unknown
    property int side: Side.Kind.Unknown

    // Screen rotation of the symbol's nose, degrees clockwise from up.
    property real noseAngle: 0

    property string label: ""
    property bool showLabel: true

    // Symbol size in px, before the classification's symbolScale.
    property real symbolSize: 36

    readonly property Data def: Database.dataFor(symbol.classification)

    width: symbolSize * def.symbolScale
    height: width

    ShapePolygon {
        anchors.fill: parent
        rotation: symbol.noseAngle
        points: symbol.def.outline
        fillColor: {
            switch (symbol.side) {
            case Side.Kind.Ownship:
                return Style.theme.factionOwnship;
            case Side.Kind.Friendly:
                return Style.theme.factionFriendly;
            case Side.Kind.Neutral:
                return Style.theme.factionNeutral;
            case Side.Kind.Hostile:
                return Style.theme.factionHostile;
            default:
                return Style.theme.factionUnknown;
            }
        }
    }

    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 2
        visible: symbol.showLabel
        text: symbol.label !== "" ? symbol.label : symbol.def.label
        color: Style.theme.textLabel
        font.pixelSize: 10
    }
}
