import QtQuick
import "../themes"

// One control cap: the player-facing name of a bound key or button, or a dash
// where nothing is bound. Fixed height and a floor under its width, so a row
// does not reflow as the player rebinds it. Shared by the settings page and the
// hint line, so a control reads the same in both.
Rectangle {
    id: root

    // What the control is called; empty renders as unbound.
    property string label: ""

    // Waiting for the player to press a control, or having just lost one to
    // another ability.
    property bool waiting: false
    property bool displaced: false

    readonly property bool bound: root.label !== ""

    // One tint carries the state: bright while capturing, warn just after
    // another ability took this control away, plain otherwise.
    readonly property color tint: {
        if (root.waiting)
            return Style.theme.accentBright;
        if (root.displaced)
            return Style.theme.warn;
        return root.bound ? Style.theme.textPrimary : Style.theme.textMuted;
    }

    implicitWidth: Math.max(64, caption.implicitWidth + 14)
    implicitHeight: 22
    radius: Style.theme.panelRadius
    color: root.bound ? Style.theme.instrumentBackground : "transparent"
    border.width: 1
    border.color: root.waiting || root.displaced ? root.tint : (root.bound ? Style.theme.frameInner : Style.theme.textMuted)

    Text {
        id: caption

        anchors.centerIn: parent
        text: root.waiting ? qsTr("PRESS…") : (root.bound ? root.label : "—")
        color: root.tint
        font { pixelSize: 12; bold: true; family: Style.monospace }
    }
}
