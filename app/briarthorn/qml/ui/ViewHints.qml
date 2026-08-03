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

    text: root.device.pad ? qsTr("LEFT STICK fly · D-PAD range · START controls") : qsTr("W thrust · A/D turn · WHEEL range · ESC controls")
    color: Style.theme.textMuted
    font { pixelSize: 12; family: Style.monospace }
}
