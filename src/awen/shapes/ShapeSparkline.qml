import QtQuick
import QtQuick.Shapes

// A compact time-series: a stroked trace over an optional area fill, with an
// optional horizontal reference line. Values map left to right, oldest first;
// the vertical scale pins to maxValue or autoscales over the data with the
// reference value as a floor.
Shape {
    id: root

    // The series, oldest first.
    property list<real> values

    // Fixed scale top; 0 autoscales from the data and referenceValue.
    property real maxValue: 0

    // Autoscale margin above the peak.
    property real headroom: 1.15

    // Height of the reference line; 0 draws none. Also the autoscale floor.
    property real referenceValue: 0

    property color strokeColor: "white"
    property real strokeWidth: 1.5
    property color fillColor: "transparent"
    property color referenceColor: "#808080"

    // The resolved scale top: maxValue when pinned, else the larger of the
    // data peak and the reference floor, with headroom.
    readonly property real scaleMax: {
        if (maxValue > 0)
            return maxValue;
        let peak = referenceValue;
        for (let i = 0; i < values.length; ++i)
            peak = Math.max(peak, values[i]);
        return peak > 0 ? peak * headroom : 1;
    }

    // Whether the reference line lands inside the scale.
    readonly property bool referenceVisible: referenceValue > 0 && referenceValue < scaleMax

    // The y for a value under the current scale — for app-side markers.
    function yFor(v: real): real {
        return height - v / scaleMax * height;
    }

    // The trace in item-space pixels.
    readonly property list<point> tracePolyline: {
        const n = values.length;
        if (n === 0)
            return [];
        const out = [];
        const dx = n > 1 ? width / (n - 1) : 0;
        for (let i = 0; i < n; ++i)
            out.push(Qt.point(i * dx, yFor(values[i])));
        return out;
    }

    // The trace closed down to the baseline, for the area fill.
    readonly property list<point> areaPolyline: {
        const n = values.length;
        if (n < 2)
            return [];
        const out = [];
        const dx = width / (n - 1);
        for (let i = 0; i < n; ++i)
            out.push(Qt.point(i * dx, yFor(values[i])));
        out.push(Qt.point(width, height));
        out.push(Qt.point(0, height));
        out.push(out[0]);
        return out;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: "transparent"

        PathPolyline {
            path: root.areaPolyline
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.strokeColor
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.RoundJoin

        PathPolyline {
            path: root.tracePolyline
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: root.referenceVisible ? root.referenceColor : "transparent"
        strokeWidth: 1
        startX: 0
        startY: root.yFor(root.referenceValue)

        PathLine {
            x: root.width
            y: root.yFor(root.referenceValue)
        }
    }
}
