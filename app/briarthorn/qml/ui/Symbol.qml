pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import awen.shapes
import "../database"
import "../model"
import "../themes"

// A scope symbol: the classification's outline polygon stroked in its side's
// colour over a window-background fill, nose turned to noseAngle, with a
// screen-upright label below and optional condition arcs on its flanks — hull
// left, fuel right. Centre it on the plot point; an empty label falls back to
// the classification's. Inside a rotated view, bind viewRotation to the
// container's rotation so the label and the arcs counter-rotate and hold their
// screen-upright places.
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

    // Condition arcs: whether the caller holds a hull or fuel reading for this
    // contact, and the readings themselves as fractions of full. Whether a
    // reading is worth drawing is the kind's call, not the caller's — only a
    // row asking for gauges gets them, so a munition mark and the bare
    // instrument marks plot without. Fuel is ownship's alone: no sensor ever
    // reports what is in another aircraft's tanks.
    property bool hasHealth: false
    property real healthFrac: 1
    property bool hasFuel: false
    property real fuelFrac: 1

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

    readonly property bool showHealth: root.hasHealth && root.def.conditionGauge
    readonly property bool showFuel: root.hasFuel && root.def.conditionGauge

    // A reading this far down goes to the warn colour — the same thresholds
    // the ownship condition instrument reads at.
    readonly property bool healthLow: root.healthFrac <= 0.3
    readonly property bool fuelLow: root.fuelFrac <= 0.2

    // Gauge geometry: arcs standing just clear of the symbol's own extent,
    // weighted off the mark so a mark drawn small carries a thin arc. A third
    // of a circle each, so a flank reads as a bar beside the mark rather than
    // a ring around it.
    readonly property real gaugeStrokeWidth: Math.max(2, root.width * 0.1)
    readonly property real gaugeRadius: root.width * 0.62
    readonly property real gaugeSweep: 120

    // How far a flank's lower end hangs below the mark's own bounds. The span
    // is centred on its flank, so the ends sit sin(half-span) of the radius
    // below the centre. The caption clears it, so a gauged mark's label seats
    // exactly that much lower than a bare one's.
    readonly property real gaugeOverhang: Math.max(0, root.gaugeRadius * Math.sin(root.gaugeSweep * Math.PI / 360) + root.gaugeStrokeWidth / 2 - root.height / 2)
    readonly property real labelGap: Math.max(2, root.symbolSize * 0.07)

    // The box either arc needs, so both flanks seat off one number.
    readonly property real gaugeSide: 2 * (root.gaugeRadius + root.gaugeStrokeWidth / 2)

    // Hull on the left flank, swept clockwise up from 7 o'clock so damage
    // drains the arc downward.
    readonly property Component healthArc: Component {
        ShapeGauge {
            strokeWidth: root.gaugeStrokeWidth
            angleStart: 270 - root.gaugeSweep / 2
            angleSweep: root.gaugeSweep
            value: root.healthFrac
            trackColor: Style.theme.gaugeTrack
            fillColor: root.healthLow ? Style.theme.warn : root.sideColor
        }
    }

    // Fuel mirrors it on the right, so ownship carries the pair as one
    // instrument and both readings drain toward the bottom together.
    readonly property Component fuelArc: Component {
        ShapeGauge {
            strokeWidth: root.gaugeStrokeWidth
            angleStart: 90 + root.gaugeSweep / 2
            angleSweep: -root.gaugeSweep
            value: root.fuelFrac
            trackColor: Style.theme.gaugeTrack
            fillColor: root.fuelLow ? Style.theme.warn : Style.theme.fuel
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

        // The condition arcs, loaded on demand — a scope in a dogfight plots
        // far more ungauged marks than gauged ones, and a shape each of those
        // builds only to keep hidden is a shape too many.
        Loader {
            anchors.centerIn: parent
            width: root.gaugeSide
            height: width
            active: root.showHealth
            sourceComponent: root.healthArc
        }

        Loader {
            anchors.centerIn: parent
            width: root.gaugeSide
            height: width
            active: root.showFuel
            sourceComponent: root.fuelArc
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
                topMargin: root.labelGap + (root.showHealth || root.showFuel ? root.gaugeOverhang : 0)
            }
        }
    }
}
