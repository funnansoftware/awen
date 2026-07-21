import QtQuick
import QtQuick.Shapes
import "bearing.js" as Bearing

// A stroked arc in bearing degrees (0 = up, clockwise); the default sweep
// draws a full circle. Stroke only — filled pies are ShapeSector's job.
Shape {
    id: root

    // Arc radius; defaults to the largest circle that keeps the stroke inside
    // the item's bounds.
    property real radius: Math.min(width, height) / 2 - strokeWidth / 2

    // Bearing of the arc's start, degrees clockwise from up.
    property real angleStart: 0

    // Arc extent in degrees, clockwise positive.
    property real angleSweep: 360

    // The arc's centre in item coordinates; defaults to the item's middle.
    property real centerX: width / 2
    property real centerY: height / 2

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle
    property alias strokeStyle: path.strokeStyle
    property alias dashPattern: path.dashPattern

    // The point at bearing angleDeg and distance r from the arc's centre.
    function pointAt(angleDeg: real, r: real): point {
        return Bearing.point(centerX, centerY, angleDeg, r);
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap

        PathAngleArc {
            centerX: root.centerX
            centerY: root.centerY
            radiusX: root.radius
            radiusY: root.radius
            startAngle: root.angleStart - 90
            sweepAngle: root.angleSweep
        }
    }
}
