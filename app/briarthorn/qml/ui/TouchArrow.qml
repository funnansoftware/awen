import QtQuick
import awen.shapes
import "../themes"

// One round touch step control: a disc carrying a triangle, for a control that
// steps a setting rather than invokes something. It answers on press as
// TouchButton does, so touch matches the rising edge a key or a pad button
// fires on; unlike an ability it has nothing to run out of and no clock to
// wind, so the rim is a plain frame.
Item {
    id: root

    // Which way the triangle points. The control is the same either way, so one
    // property covers both halves of a pair.
    property bool up: true

    // The shorter half-extent, so the disc stays round and centred off-square.
    readonly property real span: Math.min(width, height) / 2

    // True while the control is held.
    readonly property alias held: handler.active

    readonly property color tint: root.held ? Style.theme.accentBright : Style.theme.accent

    signal tapped

    implicitWidth: 44
    implicitHeight: implicitWidth

    // Confine hit-testing to the visible disc, so a press in the square's bare
    // corners falls through to the scope instead of stepping the setting.
    containmentMask: QtObject {
        function contains(pt: point): bool {
            return Math.hypot(pt.x - root.width / 2, pt.y - root.height / 2) <= root.span;
        }
    }

    // A filled disc, so the control reads against the scope behind it.
    Rectangle {
        anchors.centerIn: parent
        width: root.span * 2
        height: width
        radius: width / 2
        color: Style.theme.panelBackground
        border.color: root.tint
        border.width: 2
        opacity: root.held ? 1 : 0.8

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    ShapePolygon {
        anchors.centerIn: parent
        width: root.span
        height: width
        rotation: root.up ? 0 : 180
        points: [Qt.point(0, -0.4), Qt.point(0.4, 0.25), Qt.point(-0.4, 0.25)]
        fillColor: root.tint
    }

    // A single point, grabbed on press and held until release — no drag
    // threshold, so the control fires the moment it is touched, and its own
    // point, so a thumb here and one on the stick work at the same time.
    // Buttons are ignored outright: a touchscreen point this handler is
    // already tracking is also delivered as a synthetic left-button press,
    // which de-activates the handler and re-activates it under the one finger
    // — and this control steps a setting on that rising edge, so a single tap
    // would range twice and run the picture to its stop.
    PointHandler {
        id: handler
        acceptedButtons: Qt.NoButton
        onActiveChanged: if (handler.active)
            root.tapped()
    }
}
