import QtQuick
import "../themes"

// The full-width top status band: a themed strip across the top edge carrying
// persistent meta-game readouts — the credit purse now, with room for more — on
// the left, and the build version on the right. The corner instruments sit below
// it. Distinct from ViewStatus (the ownship's hull/fuel condition): this band is
// campaign/meta state. Ports briardart's TopStatusBar (ui/panels/top_status_bar).
Rectangle {
    id: root

    // Persistent readouts.
    property int credits: 0
    property string version: ""

    implicitHeight: 32
    color: Style.theme.panelBackground

    // A hairline along the bottom edge separates the band from the scope below.
    Rectangle {
        height: 1
        color: Style.theme.frameInner
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    }

    // Persistent readouts, left-aligned. Add more as another Stat (with a
    // Divider woven between) — e.g. Stat { label: "LVL"; value: level }.
    Row {
        spacing: 10
        anchors { left: parent.left; leftMargin: 16; verticalCenter: parent.verticalCenter }

        Stat {
            value: root.credits.toLocaleString(Qt.locale(), 'f', 0)
            unit: qsTr("CR")
        }
    }

    // The build version, right-aligned and dim.
    Text {
        text: root.version
        color: Style.theme.textMuted
        font { pixelSize: 12; family: Style.monospace }
        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
    }

    // One readout chip: an optional dim label, the bright value, and an optional
    // dim unit (e.g. CR). The shared building block for every stat.
    component Stat: Row {
        property string label: ""
        property string value: ""
        property string unit: ""

        spacing: 4

        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: parent.label
            color: Style.theme.textLabel
            font { pixelSize: 10; bold: true; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            color: Style.theme.textPrimary
            font { pixelSize: 15; bold: true; family: Style.monospace }
        }

        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: parent.unit
            color: Style.theme.textLabel
            font { pixelSize: 10; bold: true; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }
    }

    // A thin vertical divider to weave between successive stats.
    component Divider: Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 16
        color: Style.theme.frameInner
    }
}
