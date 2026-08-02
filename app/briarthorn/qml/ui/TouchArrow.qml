import QtQuick
import awen.shapes
import "../themes"

// One round touch step control: a disc carrying a triangle, for a control that
// steps a setting rather than invokes something. It answers on press as
// TouchButton does, so touch matches the rising edge a key or a pad button
// fires on; unlike an ability it has nothing to run out of and no clock to
// wind, so the rim is a plain frame.
Item {
    id: arrow

    // Which way the triangle points. The control is the same either way, so one
    // property covers both halves of a pair.
    property bool up: true

    signal tapped

    implicitWidth: 44
    implicitHeight: implicitWidth

    // The shorter half-extent, so the disc stays round and centred off-square.
    readonly property real span: Math.min(width, height) / 2

    // True while the control is held.
    readonly property alias held: handler.active

    readonly property color tint: arrow.held ? Style.theme.accentBright : Style.theme.accent

    // A filled disc, so the control reads against the scope behind it.
    Rectangle {
        anchors.centerIn: parent
        width: arrow.span * 2
        height: width
        radius: width / 2
        color: Style.theme.panelBackground
        border.color: arrow.tint
        border.width: 2
        opacity: arrow.held ? 1 : 0.8

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    ShapePolygon {
        anchors.centerIn: parent
        width: arrow.span
        height: width
        rotation: arrow.up ? 0 : 180
        points: [Qt.point(0, -0.4), Qt.point(0.4, 0.25), Qt.point(-0.4, 0.25)]
        fillColor: arrow.tint
    }

    // Confine hit-testing to the visible disc, so a press in the square's bare
    // corners falls through to the scope instead of stepping the setting.
    containmentMask: QtObject {
        function contains(pt: point): bool {
            return Math.hypot(pt.x - arrow.width / 2, pt.y - arrow.height / 2) <= arrow.span;
        }
    }

    // A single point, grabbed on press and held until release — no drag
    // threshold, so the control fires the moment it is touched, and its own
    // point, so a thumb here and one on the stick work at the same time.
    PointHandler {
        id: handler
        onActiveChanged: if (handler.active)
            arrow.tapped()
    }
}
