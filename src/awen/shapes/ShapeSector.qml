import QtQuick
import QtQuick.Shapes
import "bearing.js" as Bearing

// A filled pie wedge from the item's centre — radar cones and beam sweeps.
// Specified boresight-first: angleAt is the wedge's centre bearing and
// angleSpan its total width.
Shape {
    id: root

    // Wedge radius; defaults to the largest circle that keeps the stroke
    // inside the item's bounds.
    property real radius: Math.min(width, height) / 2 - strokeWidth / 2

    // Bearing of the wedge's centre, degrees clockwise from up.
    property real angleAt: 0

    // Total angular width of the wedge, in degrees.
    property real angleSpan: 60

    property color fillColor: "white"

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth

    // The point at bearing angleDeg and distance r from the item's centre.
    function pointAt(angleDeg: real, r: real): point {
        return Bearing.point(width / 2, height / 2, angleDeg, r);
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: root.fillColor
        strokeColor: "transparent"
        startX: root.width / 2
        startY: root.height / 2

        // moveToStart off, so the path line-connects the centre to the arc's
        // start instead of opening a new subpath.
        PathAngleArc {
            moveToStart: false
            centerX: root.width / 2
            centerY: root.height / 2
            radiusX: root.radius
            radiusY: root.radius
            startAngle: root.angleAt - root.angleSpan / 2 - 90
            sweepAngle: root.angleSpan
        }

        PathLine {
            x: root.width / 2
            y: root.height / 2
        }
    }
}
