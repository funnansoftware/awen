import QtQuick
import awen.shapes

// A spring-return virtual thumbstick driven by touch or mouse. The whole pad
// is the target; the thumb tracks the held point clamped to the rim and
// springs back to centre on release. Deflection reports as valueX (-1 left ..
// 1 right) and valueY (-1 back .. 1 forward, screen-up is forward), both zero
// at rest — wire them straight into an Axis.invoke().
Item {
    id: root

    implicitWidth: 150
    implicitHeight: implicitWidth // keep the pad square as the width scales

    // The shorter half-extent, so geometry stays centred even off-square.
    readonly property real span: Math.min(width, height) / 2
    // The thumb's maximum throw from centre in px; deflection normalises to it.
    readonly property real travel: span - thumb.width / 2

    // Thumb offset from centre in px, clamped to travel, zero while released.
    readonly property point deflection: {
        if (!handler.active)
            return Qt.point(0, 0);
        const dx = handler.point.position.x - width / 2;
        const dy = handler.point.position.y - height / 2;
        const mag = Math.hypot(dx, dy);
        if (mag > travel && mag > 0)
            return Qt.point(dx / mag * travel, dy / mag * travel);
        return Qt.point(dx, dy);
    }

    // Steering, -1 (full left) .. 1 (full right); the screen x, normalised.
    readonly property real valueX: travel > 0 ? deflection.x / travel : 0
    // Throttle, -1 (full back) .. 1 (full forward); screen-up is forward, so
    // the screen y is negated.
    readonly property real valueY: travel > 0 ? -deflection.y / travel : 0

    // True while the pad is held.
    readonly property alias active: handler.active

    // Gates the spring so the thumb is placed at centre on load rather than
    // animating in from the origin.
    property bool settled: false
    Component.onCompleted: settled = true

    // A dim filled disc so the pad reads as a control against the scope.
    Rectangle {
        anchors.centerIn: parent
        width: root.span * 2
        height: width
        radius: width / 2
        color: Style.theme.panelBackground
    }

    // The rim, and a fainter ring marking the thumb's full throw.
    ShapeRing {
        anchors.fill: parent
        gapLength: 0
        strokeColor: Style.theme.rangeRing
        strokeWidth: 2
    }

    ShapeRing {
        anchors.fill: parent
        radius: root.travel
        gapLength: 0
        strokeColor: Style.theme.gaugeTrack
        strokeWidth: 1
    }

    Rectangle {
        id: thumb
        width: Math.round(root.span * 0.7)
        height: width
        radius: width / 2
        x: root.width / 2 - width / 2 + root.deflection.x
        y: root.height / 2 - height / 2 + root.deflection.y
        color: Style.theme.factionOwnship
        opacity: root.active ? 0.85 : 0.45
        border.color: Style.theme.accentBright
        border.width: 2

        // Ease back to centre on release; the value is already zero by then, so
        // this is only the visual return.
        Behavior on x {
            enabled: root.settled && !root.active
            NumberAnimation { duration: 140; easing.type: Easing.OutBack }
        }
        Behavior on y {
            enabled: root.settled && !root.active
            NumberAnimation { duration: 140; easing.type: Easing.OutBack }
        }
        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // Confine hit-testing to the visible disc, so a press in the square's bare
    // corners falls through instead of snapping the stick to a diagonal.
    containmentMask: QtObject {
        function contains(pt: point): bool {
            return Math.hypot(pt.x - root.width / 2, pt.y - root.height / 2) <= root.span;
        }
    }

    // A single point, grabbed on press anywhere in the pad and tracked until
    // release — no drag threshold, so the stick answers the moment it's touched.
    PointHandler {
        id: handler
    }
}
