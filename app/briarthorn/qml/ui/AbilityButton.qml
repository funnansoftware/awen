import QtQuick
import "../model"
import "../themes"

// One ability control: a square button captioned with what it invokes, counting
// off what it has left, and topped with the key or controller button that fires
// it. A bar across its foot is the readiness dial — it fills back up as a
// cooldown runs off — and the whole control dims while a press would do
// nothing, naming in a word what it is waiting on, so a thumb is never left
// guessing at a control that answers nothing. A shot held armed breathes in the
// arming colour until it flies; a press that could never have fired flashes
// once instead. Shared by the touch rack and the desktop row, so an ability
// reads the same however it is flown.
Item {
    id: root

    // The caption, and the uses left; -1 is unlimited and shows no count.
    property string label: ""
    property int charges: -1

    // Whether a press would fire this instant, whether one is being held
    // against a check that has not passed yet, and what that check is — the
    // three facts the control colours and captions itself from.
    property bool valid: true
    property bool armed: false
    property int impediment: AbilitySlot.Impediment.None

    // How much of the cooldown is still to run — 1 the moment it pops, 0 once
    // the control is ready again.
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

    // One tint carries the state: the arming colours while a shot is held,
    // bright under the thumb, plain when the control would fire, muted while
    // it is cooling, spent or without a lock.
    readonly property color tint: {
        if (root.armed)
            return root.valid ? Style.theme.armValid : Style.theme.armInvalid;
        if (root.held)
            return Style.theme.accentBright;
        return root.valid ? Style.theme.accent : Style.theme.textMuted;
    }

    // The one word the control reads out in place of its count: what the
    // press is waiting on, or that it is waiting at all. A cooldown says
    // nothing here — the dial across the foot already draws it.
    readonly property string status: {
        if (root.armed)
            return qsTr("ARMED");
        switch (root.impediment) {
        case AbilitySlot.Impediment.Empty:
            return qsTr("EMPTY");
        case AbilitySlot.Impediment.NoLock:
            return qsTr("NO LOCK");
        case AbilitySlot.Impediment.Distant:
            return qsTr("RANGE");
        case AbilitySlot.Impediment.NoTarget:
            return qsTr("NO TARGET");
        default:
            return "";
        }
    }

    // Fired on press rather than on release: a control that answers as the
    // thumb lands matches the rising edge a key or a pad button fires on.
    signal tapped

    // Fired with it when the press came from a touchscreen, so the HUD can hand
    // the interface back to the touch controls the moment a thumb lands on one.
    signal touched

    implicitWidth: 74
    implicitHeight: implicitWidth

    // A press that could never have fired — an empty rack — beats the panel in
    // the caution colour, so a dead control answers rather than swallowing it.
    function refuse() {
        refusal.restart();
    }

    // A filled panel, so the control reads against the scope behind it.
    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.panelBackground
        opacity: root.held ? 1 : 0.85
        border.width: root.held || root.armed ? 2 : 1
        border.color: root.tint

        Behavior on opacity {
            NumberAnimation { duration: 120 }
        }
    }

    // The armed breathing: a wash of the arming colour over the whole panel
    // while a shot is held, so a rack the player is not looking at still says
    // it is waiting. Its opacity is the animation's alone — a binding here
    // would fight the value source.
    Rectangle {
        id: glow

        anchors.fill: parent
        visible: root.armed
        radius: Style.theme.panelRadius
        color: Qt.alpha(root.tint, 0.22)

        SequentialAnimation on opacity {
            running: glow.visible
            loops: Animation.Infinite

            NumberAnimation { from: 1; to: 0.15; duration: 320 }
            NumberAnimation { from: 0.15; to: 1; duration: 320 }
        }
    }

    // The refusal beat, raised by refuse(): three quick pulses and gone. Shown
    // only while it runs, so the wash never needs a resting value the
    // animation would have to hold the property at.
    Rectangle {
        anchors.fill: parent
        visible: refusal.running
        radius: Style.theme.panelRadius
        color: Style.theme.armInvalid

        SequentialAnimation on opacity {
            id: refusal

            running: false
            loops: 3

            NumberAnimation { from: 0; to: 0.5; duration: 80 }
            NumberAnimation { from: 0.5; to: 0; duration: 120 }
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
            color: root.valid ? Style.theme.textPrimary : Style.theme.textMuted
            font { pixelSize: Math.max(9, root.span * 0.15); bold: true; letterSpacing: root.span * 0.015; family: Style.monospace }
        }

        // The rounds left, or — where the control has something to say about
        // why a press would not fire — that state in a word instead. One row
        // either way, so a rack of small buttons never grows to carry it.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.status !== "" || root.charges >= 0
            width: root.span * 0.94
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.status !== "" ? root.status : root.charges
            color: {
                if (root.status !== "")
                    return root.armed ? root.tint : Style.theme.armInvalid;
                return Style.theme.textLabel;
            }
            font.pixelSize: Math.max(8, root.span * (root.status !== "" ? 0.12 : 0.14))
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
