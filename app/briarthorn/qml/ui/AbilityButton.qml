import QtQuick
import "../themes"

// One ability control: a square button captioned with what it invokes, counting
// off what it has left, and topped with the key or controller button that fires
// it. A bar across its foot is the readiness dial — it fills back up as a
// cooldown runs off — and the whole control dims while a press would do
// nothing, so a thumb is never left waiting on a spent one. Shared by the touch
// rack and the desktop row, so an ability reads the same however it is flown.
Item {
    id: root

    // The caption, and the uses left; -1 is unlimited and shows no count.
    property string label: ""
    property int charges: -1

    // Whether a press would fire, and how much of the cooldown is still to run
    // — 1 the moment it pops, 0 once the control is ready again.
    property bool ready: true
    property real cooling: 0

    // The control that fires this ability, as the cap over the caption draws
    // it: its player-facing name, whether it is a controller button, and that
    // button's code, which picks the face colour. The cap keeps its place while
    // nothing is bound, so a row does not shuffle as the player rebinds;
    // showControl drops it outright, for a rack driven by the thumb on the
    // button itself.
    property string control: ""
    property bool pad: false
    property int code: -1
    property bool showControl: true

    // The shorter extent, so the button's contents scale together off-square.
    readonly property real span: Math.min(width, height)

    // True while the control is held.
    readonly property alias held: handler.active

    // One tint carries the state: bright under the thumb, plain when the
    // control would fire, muted while it is cooling or spent.
    readonly property color tint: {
        if (root.held)
            return Style.theme.accentBright;
        return root.ready ? Style.theme.accent : Style.theme.textMuted;
    }

    // Fired on press rather than on release: a control that answers as the
    // thumb lands matches the rising edge a key or a pad button fires on.
    signal tapped

    // Fired with it when the press came from a touchscreen, so the HUD can hand
    // the interface back to the touch controls the moment a thumb lands on one.
    signal touched

    implicitWidth: 74
    implicitHeight: implicitWidth

    // A filled panel, so the control reads against the scope behind it.
    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.panelBackground
        opacity: root.held ? 1 : 0.85
        border.width: root.held ? 2 : 1
        border.color: root.tint

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // The bound control at the head of the button, then the caption and the
    // count: one centred block rather than three anchored pieces, so a button
    // shrunk to fit a small window crowds nothing. A rack with no cap to show
    // drops that row and the caption re-centres on its own.
    Column {
        spacing: root.span * 0.03

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: parent.verticalCenter
            // Lifted by half the dial's band, so the readout stays centred in
            // what the cooldown bar leaves rather than in the whole square.
            verticalCenterOffset: -root.span * 0.05
        }

        ControlCap {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.showControl
            pad: root.pad
            code: root.code
            label: root.control
            fontSize: Math.max(9, root.span * 0.2)
            minimumWidth: 0
        }

        // The caption fills the panel and its tracking scales with it: at the
        // floor size a fixed 1px of letter spacing is the difference between
        // the longest ability name fitting and eliding.
        Text {
            width: root.span * 0.94
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.label
            color: root.ready ? Style.theme.textPrimary : Style.theme.textMuted
            font { pixelSize: Math.max(9, root.span * 0.15); bold: true; letterSpacing: root.span * 0.015; family: Style.monospace }
        }

        // The rounds left, where the control counts them at all; an empty rack
        // reads in the warn colour rather than quietly showing a zero.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.charges >= 0
            text: root.charges
            color: root.charges === 0 ? Style.theme.warn : Style.theme.textLabel
            font.pixelSize: Math.max(9, root.span * 0.14)
            font.family: Style.monospace
        }
    }

    // The readiness dial: nothing at all while the control is ready, and a bar
    // across the foot filling back up as the cooldown runs off.
    Rectangle {
        id: track

        visible: root.cooling > 0
        height: Math.max(2, root.span * 0.045)
        color: Style.theme.gaugeTrack

        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: root.span * 0.09
        }

        Rectangle {
            width: track.width * (1 - Math.max(0, Math.min(1, root.cooling)))
            height: parent.height
            color: root.tint
        }
    }

    // A single point, grabbed on press and held until release — no drag
    // threshold, so the control fires the moment it is touched, and its own
    // point, so a thumb here and one on the stick work at the same time.
    // Buttons are ignored outright: a touchscreen point this handler is already
    // tracking is also delivered as a synthetic left-button press, which
    // de-activates the handler and re-activates it under the one finger — and
    // the invocation rides that rising edge, so a single tap would fire twice
    // and a flare off no cooldown would spend two decoys.
    PointHandler {
        id: handler

        acceptedButtons: Qt.NoButton
        onActiveChanged: if (handler.active) {
            if (handler.point.device.type === PointerDevice.TouchScreen)
                root.touched();
            root.tapped();
        }
    }
}
