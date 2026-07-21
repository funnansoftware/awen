import QtQuick
import QtQuick.Shapes
import "bearing.js" as Bearing

// Radial ticks around a circle, drawn inward from radius every stepAngle
// degrees. angleOffset rotates the assembly (heading-up displays); ticks whose
// on-screen bearing falls inside the gap window are suppressed — bind gapAngle
// and gapHalfAngle from a ShapeRing's readouts.
Shape {
    id: root

    // Angular spacing between ticks, in degrees.
    property real stepAngle: 30

    // Screen rotation added to every tick bearing, in degrees.
    property real angleOffset: 0

    // Radius of the ticks' outer end; defaults to the largest circle that
    // keeps the stroke inside the item's bounds.
    property real radius: Math.min(width, height) / 2 - strokeWidth / 2

    // Tick length, drawn inward from radius.
    property real length: 14

    // The suppression window's centre bearing and half-width, in screen
    // degrees; a zero half-width suppresses nothing.
    property real gapAngle: 0
    property real gapHalfAngle: 0

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle

    // The visible ticks' fixed bearings (before angleOffset), gap-suppressed
    // by their on-screen position.
    readonly property list<real> tickAngles: {
        const out = [];
        if (stepAngle <= 0)
            return out;
        for (let a = 0; a < 360 - 1e-9; a += stepAngle) {
            if (gapHalfAngle > 0 && Bearing.distanceDeg(a + angleOffset, gapAngle) < gapHalfAngle)
                continue;
            out.push(a);
        }
        return out;
    }

    // The on-screen point for a tick bearing at distance r — the label anchor;
    // applies angleOffset.
    function tickPoint(bearing: real, r: real): point {
        return Bearing.point(width / 2, height / 2, bearing + angleOffset, r);
    }

    // All ticks as one multi-subpath SVG string, rebuilt as a single binding.
    readonly property string tickPath: {
        let d = "";
        const cx = width / 2;
        const cy = height / 2;
        for (let i = 0; i < tickAngles.length; ++i) {
            const a = tickAngles[i] + angleOffset;
            const outer = Bearing.point(cx, cy, a, radius);
            const inner = Bearing.point(cx, cy, a, radius - length);
            d += "M " + outer.x + " " + outer.y + " L " + inner.x + " " + inner.y + " ";
        }
        return d;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap

        // PathSvg must stay the sole element of its ShapePath.
        PathSvg {
            path: root.tickPath
        }
    }
}
