import QtQuick
import QtQuick.Shapes

// A cubic connector between two points, with optional dashing, a glow
// understroke and an arrowhead — the graph-edge primitive. Default controls
// give horizontal end tangents; override them to route through corridors.
// Qt dash patterns are in stroke-width units, not pixels: a 6-4 px dash at
// width 1.5 is dashPattern: [4, 2.67].
Shape {
    id: root

    property point from: Qt.point(0, 0)
    property point to: Qt.point(0, 0)

    // Horizontal-tangent reach of the default control points, as a fraction of
    // the endpoints' x distance.
    property real tangent: 0.45

    property point fromControl: Qt.point(from.x + tangent * (to.x - from.x), from.y)
    property point toControl: Qt.point(to.x - tangent * (to.x - from.x), to.y)

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias strokeStyle: path.strokeStyle
    property alias dashPattern: path.dashPattern
    property alias capStyle: path.capStyle

    // The glow understroke's color; transparent draws none. It strokes the
    // same cubic glowExtra wider than the main line.
    property color glowColor: "transparent"
    property real glowExtra: 4

    property bool arrowhead: false
    property real arrowSize: 6

    // The arrowhead chevron, oriented along the arrival tangent; a degenerate
    // tangent (toControl on the endpoint) falls back to the chord direction.
    readonly property list<point> arrowPolyline: {
        if (!arrowhead)
            return [];
        let dx = to.x - toControl.x;
        let dy = to.y - toControl.y;
        if (Math.hypot(dx, dy) < 0.001) {
            dx = to.x - from.x;
            dy = to.y - from.y;
        }
        const len = Math.hypot(dx, dy);
        if (len < 0.001)
            return [];
        const ux = dx / len;
        const uy = dy / len;
        const bx = to.x - ux * arrowSize;
        const by = to.y - uy * arrowSize;
        const w = arrowSize * 2 / 3;
        return [Qt.point(bx - uy * w, by + ux * w), to, Qt.point(bx + uy * w, by - ux * w)];
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.glowColor
        strokeWidth: path.strokeWidth + root.glowExtra
        capStyle: ShapePath.RoundCap
        startX: root.from.x
        startY: root.from.y

        PathCubic {
            x: root.to.x
            y: root.to.y
            control1X: root.fromControl.x
            control1Y: root.fromControl.y
            control2X: root.toControl.x
            control2Y: root.toControl.y
        }
    }

    ShapePath {
        id: path
        fillColor: "transparent"
        startX: root.from.x
        startY: root.from.y

        PathCubic {
            x: root.to.x
            y: root.to.y
            control1X: root.fromControl.x
            control1Y: root.fromControl.y
            control2X: root.toControl.x
            control2Y: root.toControl.y
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.arrowhead ? path.strokeColor : "transparent"
        strokeWidth: path.strokeWidth
        capStyle: ShapePath.RoundCap
        joinStyle: ShapePath.RoundJoin

        PathPolyline {
            path: root.arrowPolyline
        }
    }
}
