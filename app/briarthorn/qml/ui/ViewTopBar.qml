import QtQuick
import "../themes"

// The full-width top status band: a themed strip across the top edge carrying
// persistent meta-game readouts — the credit purse now, with room for more — on
// the left, and the build version on the right. The corner instruments sit below
// it. Distinct from ViewStatus (the ownship's hull/fuel condition): this band is
// campaign/meta state. Ports briardart's TopStatusBar (ui/panels/top_status_bar).
Rectangle {
    id: bar

    // Persistent readouts.
    property int credits: 0
    property string version: ""

    implicitHeight: 32
    color: Style.theme.panelBackground

    // A hairline along the bottom edge separates the band from the scope below.
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Style.theme.frameInner
    }

    // Persistent readouts, left-aligned. Add more as another Stat (with a
    // Divider woven between) — e.g. Stat { label: "LVL"; value: level }.
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Stat {
            value: bar.credits.toLocaleString(Qt.locale(), 'f', 0)
            unit: qsTr("CR")
        }
    }

    // The build version, right-aligned and dim.
    Text {
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        text: bar.version
        color: "#66ffffff"
        font.pixelSize: 12
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
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: parent.value
            color: Style.theme.textPrimary
            font.pixelSize: 15
            font.bold: true
            font.family: "Consolas"
        }

        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: parent.unit
            color: Style.theme.textLabel
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1
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
