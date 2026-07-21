import QtQuick
import QtQuick.Shapes

// A four-armed crosshair with an open centre — the cursor primitive. Each arm
// runs from gap to gap + armLength along its axis.
Shape {
    id: root

    // Radius of the open centre, in pixels.
    property real gap: 5

    // Length of each arm, drawn outward from the gap.
    property real armLength: 9

    // The crosshair's centre in item coordinates; defaults to the item's middle.
    property real centerX: width / 2
    property real centerY: height / 2

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: "transparent"
        strokeWidth: 1.5

        PathMove { x: root.centerX; y: root.centerY - root.gap }
        PathLine { x: root.centerX; y: root.centerY - root.gap - root.armLength }

        PathMove { x: root.centerX + root.gap; y: root.centerY }
        PathLine { x: root.centerX + root.gap + root.armLength; y: root.centerY }

        PathMove { x: root.centerX; y: root.centerY + root.gap }
        PathLine { x: root.centerX; y: root.centerY + root.gap + root.armLength }

        PathMove { x: root.centerX - root.gap; y: root.centerY }
        PathLine { x: root.centerX - root.gap - root.armLength; y: root.centerY }
    }
}
