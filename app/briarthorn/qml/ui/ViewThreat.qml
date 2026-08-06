import QtQuick
import awen.shapes
import "../model"
import "../themes"

// Missile warning: flashes while a homing round is marked inbound on the
// ownship — the mark SystemThreat pins each tick — with an arrow swinging to
// the threat's bearing in the scope's heading-up frame and the closing range
// beside it.
Item {
    id: root

    // The defended craft whose threatInbound this announces.
    property Entity ownship

    readonly property Entity threat: root.ownship ? root.ownship.threatInbound : null
    readonly property bool active: root.threat !== null

    // Degrees the threat sits off the nose — the arrow's swing.
    readonly property real threatBearing: root.active ? Geo.wrap180(Geo.bearing(root.ownship, root.threat) - root.ownship.heading) : 0
    readonly property real threatRange: root.active ? Geo.distance(root.ownship, root.threat) : 0

    implicitWidth: content.implicitWidth + 32
    implicitHeight: content.implicitHeight + 14
    visible: root.active

    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.panelBackground
        border.color: Style.theme.factionHostile
        border.width: 2
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: 12

        ShapePolygon {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: width
            rotation: root.threatBearing
            points: [Qt.point(0, -0.5), Qt.point(0.38, 0.34), Qt.point(0, 0.14), Qt.point(-0.38, 0.34)]
            fillColor: Style.theme.factionHostile
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("MISSILE")
            color: Style.theme.factionHostile
            font { pixelSize: 16; family: Style.monospace; bold: true; letterSpacing: Style.theme.capsTracking }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 KM").arg((root.threatRange / 1000).toFixed(1))
            color: Style.theme.textBright
            font { pixelSize: 13; family: Style.monospace }
        }
    }

    SequentialAnimation on opacity {
        running: root.visible
        loops: Animation.Infinite

        NumberAnimation {
            from: 1
            to: 0.35
            duration: 320
        }

        NumberAnimation {
            from: 0.35
            to: 1
            duration: 320
        }
    }
}
