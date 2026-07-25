import QtQuick
import "../themes"

// One control cap: the player-facing name of a bound key or button, or a dash
// where nothing is bound. Fixed height and a floor under its width, so a row
// does not reflow as the player rebinds it. Shared by the settings page and the
// hint line, so a control reads the same in both.
Rectangle {
    id: cap

    // What the control is called; empty renders as unbound.
    property string label: ""

    // Waiting for the player to press a control, or having just lost one to
    // another ability.
    property bool waiting: false
    property bool displaced: false

    readonly property bool bound: cap.label !== ""

    // One tint carries the state: bright while capturing, warn just after
    // another ability took this control away, plain otherwise.
    readonly property color tint: {
        if (cap.waiting)
            return Style.theme.accentBright;
        if (cap.displaced)
            return Style.theme.warn;
        return cap.bound ? Style.theme.textPrimary : Style.theme.textMuted;
    }

    implicitWidth: Math.max(64, caption.implicitWidth + 14)
    implicitHeight: 22
    radius: Style.theme.panelRadius
    color: cap.bound ? Style.theme.instrumentBackground : "transparent"
    border.width: 1
    border.color: cap.waiting || cap.displaced ? cap.tint : (cap.bound ? Style.theme.frameInner : Style.theme.textMuted)

    Text {
        id: caption

        anchors.centerIn: parent
        text: cap.waiting ? qsTr("PRESS…") : (cap.bound ? cap.label : "—")
        color: cap.tint
        font.pixelSize: 12
        font.bold: true
        font.family: Style.monospace
    }
}
