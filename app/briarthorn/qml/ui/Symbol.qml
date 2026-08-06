pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import awen.shapes
import "../database"
import "../model"
import "../themes"

// A scope symbol: the classification's outline polygon stroked in its side's
// colour over a window-background fill, nose turned to noseAngle, with a
// screen-upright label below and an optional hull gauge hugging its left.
// Centre it on the plot point; an empty label falls back to the
// classification's. Inside a rotated view, bind viewRotation to the
// container's rotation so the label and the gauge counter-rotate and hold
// their screen-upright places.
Item {
    id: root

    property int classification: Classification.Kind.Unknown
    property int side: Side.Kind.Unknown

    // Rotation of the symbol's nose, degrees clockwise from the frame's up.
    property real noseAngle: 0

    // The containing view's rotation.
    property real viewRotation: 0

    property string label: ""
    property bool showLabel: true

    // Hull condition: whether the caller holds a reading for this contact at
    // all, and the reading itself as a fraction of full hull. Whether that
    // reading is worth drawing is the kind's call, not the caller's — only a
    // row asking for a gauge gets one, so a munition mark and the bare
    // instrument marks plot without.
    property bool hasHealth: false
    property real healthFrac: 1

    // Symbol size in px, before the classification's symbolScale.
    property real symbolSize: 36

    // Outline stroke width in px; starts at the range rings' weight so marks
    // and rings share one line weight on the scope.
    property real strokeWidth: 2

    readonly property Data def: Database.dataFor(root.classification)

    readonly property color sideColor: {
        switch (root.side) {
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

    readonly property bool showHealth: root.hasHealth && root.def.hullGauge

    // A hull this far down reads as a casualty, and the gauge goes to the warn
    // colour — the same threshold the ownship condition instrument uses.
    readonly property bool healthLow: root.healthFrac <= 0.3

    // Gauge geometry: an arc standing just clear of the symbol's own extent,
    // weighted off the mark so a mark drawn small carries a thin arc.
    readonly property real healthStrokeWidth: Math.max(2, root.width * 0.1)
    readonly property real healthRadius: root.width * 0.62

    // A semicircle on the left necessarily tips at 6 o'clock, below the mark's
    // own bounds; this is how far. The caption clears it, so a gauged mark's
    // label seats exactly that much lower than a bare one's.
    readonly property real healthOverhang: root.healthRadius + root.healthStrokeWidth / 2 - root.height / 2
    readonly property real labelGap: Math.max(2, root.symbolSize * 0.07)

    readonly property Component healthGauge: Component {
        ShapeGauge {
            strokeWidth: root.healthStrokeWidth
            // A left-hand semicircle filling clockwise from 6 o'clock up to
            // 12, so damage eats the arc back down toward the bottom.
            angleStart: 180
            angleSweep: 180
            value: root.healthFrac
            trackColor: Style.theme.gaugeTrack
            fillColor: root.healthLow ? Style.theme.warn : root.sideColor
        }
    }

    width: root.symbolSize * root.def.symbolScale
    height: width

    ShapePolygon {
        anchors.fill: parent
        rotation: root.noseAngle
        points: root.def.outline
        fillColor: Style.theme.windowBackground
        strokeColor: root.sideColor
        strokeWidth: root.strokeWidth
        // Round joins: the missiles' acute noses exceed the default miter
        // limit and would chop flat, and the fighter's tips would spike past
        // the item bounds the views seat marks by.
        joinStyle: ShapePath.RoundJoin
    }

    // Counter-rotating frame: cancels the view rotation so the label reads
    // upright below the symbol on screen and the gauge holds its left side.
    Item {
        anchors.fill: parent
        rotation: -root.viewRotation

        // The hull gauge, loaded only for a kind that carries one: a scope in
        // a dogfight plots far more missile marks than aircraft, and a shape
        // each of those builds only to keep hidden is a shape too many.
        Loader {
            anchors.centerIn: parent
            width: 2 * (root.healthRadius + root.healthStrokeWidth / 2)
            height: width
            active: root.showHealth
            sourceComponent: root.healthGauge
        }

        Text {
            visible: root.showLabel
            text: root.label !== "" ? root.label : root.def.label
            color: Style.theme.textLabel
            // Sized off the mark it captions, not fixed: one Symbol serves the
            // attack scope, the minimap and the condition gauge, and a constant
            // here reads as a different label on each.
            font {
                pixelSize: Math.max(8, root.symbolSize * 0.37)
                family: Style.monospace
            }

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.bottom
                topMargin: root.labelGap + (root.showHealth ? root.healthOverhang : 0)
            }
        }
    }
}
