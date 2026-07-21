import QtQuick
import QtQuick.Shapes
import "bearing.js" as Bearing

// A stroked circle with a fixed arc-length gap — the range-ring primitive.
// The gap stays a constant on-screen size at any radius; place a label on
// gapCenter and suppress ticks with inGap().
Shape {
    id: root

    // Ring radius; defaults to the largest circle that keeps the stroke inside
    // the item's bounds.
    property real radius: Math.min(width, height) / 2 - strokeWidth / 2

    // The ring's centre in item coordinates; defaults to the item's middle.
    // Rebind (e.g. centerY: height * 0.875) to shift the ring off-centre.
    property real centerX: width / 2
    property real centerY: height / 2

    // Arc length removed from the circle, in pixels; 0 draws a closed ring.
    property real gapLength: 0

    // Bearing of the gap's centre, degrees clockwise from up.
    property real gapAngle: 0

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle

    // Half the gap's angular width in degrees, clamped to a half turn.
    readonly property real gapHalfAngle: radius > 0 ? Math.min(gapLength / radius / 2, Math.PI) * 180 / Math.PI : 0

    // The gap's centre on the ring — the label anchor.
    readonly property point gapCenter: pointAt(gapAngle, radius)

    // Whether a bearing falls inside the gap; wraparound-safe.
    function inGap(angleDeg: real): bool {
        return Bearing.distanceDeg(angleDeg, gapAngle) < gapHalfAngle;
    }

    // The point at bearing angleDeg and distance r from the ring's centre.
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
            startAngle: root.gapAngle + root.gapHalfAngle - 90
            sweepAngle: 360 - 2 * root.gapHalfAngle
        }
    }
}
