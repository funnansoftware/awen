import QtQuick
import "../input"
import "../themes"

// The flight hint line: the fixed controls the craft is flown on, phrased for
// whichever device the player is driving with. It names no ability — the row of
// ability buttons beneath it carries those, captioned with their own live
// bindings — so nothing here follows a rebind.
Text {
    id: root

    // Which device the player is on; the pad and the keyboard fly the same
    // craft on entirely different controls.
    required property ActiveDevice device

    text: root.device.pad ? qsTr("LEFT STICK fly · D-PAD range · Y/LB target · START pause") : qsTr("W/S throttle · A/D turn · TAB target · WHEEL range · ESC pause")
    color: Style.theme.textMuted
    elide: Text.ElideRight // the caller caps width where the line would collide
    font { pixelSize: 12; family: Style.monospace }
}
