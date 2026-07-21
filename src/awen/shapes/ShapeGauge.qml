import QtQuick
import QtQuick.Shapes
import "bearing.js" as Bearing

// A track arc with a proportional fill arc — the dial-gauge primitive. The
// defaults give a bottom-open 270° gauge; narrower spans make status arcs
// (e.g. a health arc hugging one side of a symbol).
Shape {
    id: root

    // Fill fraction, 0..1; values outside the range clamp.
    property real value: 0

    // Bearing of the track's start, degrees clockwise from up.
    property real angleStart: 225

    // Track extent in degrees, clockwise positive.
    property real angleSweep: 270

    // Gauge radius; defaults to the largest circle that keeps the stroke
    // inside the item's bounds.
    property real radius: Math.min(width, height) / 2 - strokeWidth / 2

    // Stroke thickness shared by the track and fill arcs.
    property real strokeWidth: 6

    // The gauge's centre in item coordinates; defaults to the item's middle.
    property real centerX: width / 2
    property real centerY: height / 2

    property color trackColor: "#33ffffff"
    property color fillColor: "white"
    property int capStyle: ShapePath.RoundCap

    // The fill arc's extent in degrees.
    readonly property real fillSweep: angleSweep * Math.max(0, Math.min(1, value))

    // False at value 0, where a round cap would otherwise paint a stray dot.
    readonly property bool fillVisible: value > 0

    // The fill arc's end point — a tip-marker or label anchor.
    readonly property point fillEnd: pointAt(angleStart + fillSweep, radius)

    // The point at bearing angleDeg and distance r from the gauge's centre.
    function pointAt(angleDeg: real, r: real): point {
        return Bearing.point(centerX, centerY, angleDeg, r);
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.trackColor
        strokeWidth: root.strokeWidth
        capStyle: root.capStyle

        PathAngleArc {
            centerX: root.centerX
            centerY: root.centerY
            radiusX: root.radius
            radiusY: root.radius
            startAngle: root.angleStart - 90
            sweepAngle: root.angleSweep
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.fillVisible ? root.fillColor : "transparent"
        strokeWidth: root.strokeWidth
        capStyle: root.capStyle

        PathAngleArc {
            centerX: root.centerX
            centerY: root.centerY
            radiusX: root.radius
            radiusY: root.radius
            startAngle: root.angleStart - 90
            sweepAngle: root.fillSweep
        }
    }
}
