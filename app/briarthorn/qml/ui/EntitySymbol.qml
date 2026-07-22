import QtQuick
import awen.shapes
import "../model"
import "../themes"

// One entity's scope symbol: the classification's outline polygon, centred on
// the entity's world position with the nose along its heading, coloured by
// side. Lives inside the rotated world container; bind worldRotation to the
// container's rotation so the label counter-rotates and stays screen-upright.
Item {
    id: symbol

    required property Entity entity

    // The world container's rotation (the view's -ownship.heading).
    property real worldRotation: 0

    // Whether to draw the label; ownship's symbol usually goes without.
    property bool showLabel: true

    // Symbol size in px, before the classification's symbolScale.
    property real symbolSize: 36

    readonly property Data def: Database.dataFor(symbol.entity.classification)

    x: entity.posX - width / 2
    y: entity.posY - height / 2
    width: symbolSize * def.symbolScale
    height: width

    ShapePolygon {
        anchors.fill: parent
        rotation: symbol.entity.heading
        points: symbol.def.outline
        fillColor: {
            switch (symbol.entity.side) {
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

    // Counter-rotating frame: cancels the world rotation so the label reads
    // upright below the symbol on screen.
    Item {
        anchors.fill: parent
        rotation: -symbol.worldRotation

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.bottom
            anchors.topMargin: 2
            visible: symbol.showLabel
            text: symbol.entity.callsign !== "" ? symbol.entity.callsign : symbol.def.label
            color: Style.theme.textLabel
            font.pixelSize: 10
        }
    }
}
