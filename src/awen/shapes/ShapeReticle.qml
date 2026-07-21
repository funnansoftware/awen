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

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth
    property alias capStyle: path.capStyle

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: "transparent"
        strokeWidth: 1.5

        PathMove { x: root.width / 2; y: root.height / 2 - root.gap }
        PathLine { x: root.width / 2; y: root.height / 2 - root.gap - root.armLength }

        PathMove { x: root.width / 2 + root.gap; y: root.height / 2 }
        PathLine { x: root.width / 2 + root.gap + root.armLength; y: root.height / 2 }

        PathMove { x: root.width / 2; y: root.height / 2 + root.gap }
        PathLine { x: root.width / 2; y: root.height / 2 + root.gap + root.armLength }

        PathMove { x: root.width / 2 - root.gap; y: root.height / 2 }
        PathLine { x: root.width / 2 - root.gap - root.armLength; y: root.height / 2 }
    }
}
