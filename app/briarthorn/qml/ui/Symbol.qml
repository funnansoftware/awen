import QtQuick
import awen.shapes
import "../model"
import "../themes"

// A scope symbol: the classification's outline polygon coloured by side,
// nose turned to noseAngle, with a screen-upright label below. Centre it on
// the plot point; an empty label falls back to the classification's. Inside
// a rotated view, bind viewRotation to the container's rotation so the
// label counter-rotates and stays upright.
Item {
    id: symbol

    property int classification: Classification.Kind.Unknown
    property int side: Side.Kind.Unknown

    // Rotation of the symbol's nose, degrees clockwise from the frame's up.
    property real noseAngle: 0

    // The containing view's rotation.
    property real viewRotation: 0

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

    // Counter-rotating frame: cancels the view rotation so the label reads
    // upright below the symbol on screen.
    Item {
        anchors.fill: parent
        rotation: -symbol.viewRotation

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
}
