import QtQuick
import awen.shapes
import "../themes"

// One round touch control: a thumb-sized disc that answers the moment it is
// touched, captioned with what it invokes and counting off what it has left.
// Its rim is the readiness dial — it winds back round as a cooldown runs off —
// and the whole control dims while a press would do nothing, so a thumb is
// never left waiting on a spent one. The touch counterpart to ControlCap, and
// the stick's opposite number in the touch input set.
Item {
    id: button

    // The caption, and the uses left; -1 is unlimited and shows no count.
    property string label: ""
    property int charges: -1

    // Whether a press would fire, and how much of the cooldown is still to run
    // — 1 the moment it pops, 0 once the control is ready again.
    property bool ready: true
    property real cooling: 0

    // Fired on press rather than on release: a control that answers as the
    // thumb lands matches the rising edge a key or a pad button fires on.
    signal tapped

    implicitWidth: 88
    implicitHeight: implicitWidth

    // The shorter half-extent, so the disc stays round and centred off-square.
    readonly property real span: Math.min(width, height) / 2

    // True while the control is held.
    readonly property alias held: handler.active

    // One tint carries the state: bright under the thumb, plain when the
    // control would fire, muted while it is cooling or spent.
    readonly property color tint: {
        if (button.held)
            return Style.theme.accentBright;
        return button.ready ? Style.theme.accent : Style.theme.textMuted;
    }

    // A filled disc, so the control reads against the scope behind it.
    Rectangle {
        anchors.centerIn: parent
        width: button.span * 2
        height: width
        radius: width / 2
        color: Style.theme.panelBackground
        opacity: button.held ? 1 : 0.8

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // The rim is the cooldown dial: a closed ring while ready, winding round
    // from the top as the clock runs off.
    ShapeGauge {
        anchors.fill: parent
        radius: button.span - 2
        strokeWidth: 3
        angleStart: 0
        angleSweep: 360
        value: 1 - Math.max(0, Math.min(1, button.cooling))
        trackColor: Style.theme.gaugeTrack
        fillColor: button.tint
    }

    Column {
        anchors.centerIn: parent
        spacing: -button.span * 0.04

        Text {
            width: button.span * 1.6
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: button.label
            color: button.ready ? Style.theme.textPrimary : Style.theme.textMuted
            font.pixelSize: Math.max(9, button.span * 0.3)
            font.bold: true
            font.letterSpacing: 1
        }

        // The rounds left, where the control counts them at all; an empty rack
        // reads in the warn colour rather than quietly showing a zero.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: button.charges >= 0
            text: button.charges
            color: button.charges === 0 ? Style.theme.warn : Style.theme.textLabel
            font.pixelSize: Math.max(9, button.span * 0.28)
            font.family: Style.monospace
        }
    }

    // Confine hit-testing to the visible disc, so a press in the square's bare
    // corners falls through to the scope instead of firing the ability.
    containmentMask: QtObject {
        function contains(pt: point): bool {
            return Math.hypot(pt.x - button.width / 2, pt.y - button.height / 2) <= button.span;
        }
    }

    // A single point, grabbed on press and held until release — no drag
    // threshold, so the control fires the moment it is touched, and its own
    // point, so a thumb here and one on the stick work at the same time.
    PointHandler {
        id: handler
        onActiveChanged: if (handler.active)
            button.tapped()
    }
}
