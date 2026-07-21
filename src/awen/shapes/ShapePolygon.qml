import QtQuick
import QtQuick.Shapes

// A closed fill-plus-stroke polygon — the symbol primitive. With unitScale on,
// points live in a [-0.5, 0.5] box and scale uniformly to the item (aspect
// locked, centred); rotate and fade with the Item rotation/opacity properties.
Shape {
    id: root

    // The polygon's corners, in declaration order; closure back to the first
    // point is automatic.
    property list<point> points

    // Whether points are unit-box model coordinates (true) or item-space
    // pixels (false).
    property bool unitScale: true

    property color fillColor: "transparent"

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias joinStyle: path.joinStyle

    // The closed polygon in item-space pixels (n + 1 points, last == first) —
    // also the input for area computations like liquid fills.
    readonly property list<point> polyline: {
        if (points.length === 0)
            return [];
        const s = unitScale ? Math.min(width, height) : 1;
        const cx = unitScale ? width / 2 : 0;
        const cy = unitScale ? height / 2 : 0;
        const out = [];
        for (let i = 0; i < points.length; ++i)
            out.push(Qt.point(cx + points[i].x * s, cy + points[i].y * s));
        out.push(out[0]);
        return out;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: root.fillColor
        // Transparent, not Qt's white default: a bare polygon draws fill only.
        strokeColor: "transparent"
        strokeWidth: 1
        joinStyle: ShapePath.MiterJoin

        PathPolyline {
            path: root.polyline
        }
    }
}
