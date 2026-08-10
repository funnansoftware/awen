import QtQuick
import awen.shapes
import "../model"
import "../themes"

// Terrain warning: flashes while a pillar stands in the ownship's path — the
// wall SystemAvoidance marks each tick — with an arrow swinging to its bearing
// in the scope's heading-up frame and the distance to its face beside it.
//
// It warns and never steers. Every other craft in the sky flies maneuvers and
// so is turned around a pillar by the same system that marks it; the player's
// carries none, by design, and a hand on the stick that is quietly overridden
// is worse than a wall. So this is the whole of what the game does about the
// player and terrain, which is why it leads the alert channel: a missile can
// be beaten and a wall cannot.
Item {
    id: root

    // The craft whose terrainAhead this announces.
    property Entity ownship

    readonly property Obstacle wall: root.ownship ? root.ownship.terrainAhead : null
    readonly property bool active: root.wall !== null

    // Degrees the wall sits off the nose — the arrow's swing.
    readonly property real wallBearing: root.active ? Geo.wrap180(Geo.bearingFrom(root.ownship.posX, root.ownship.posY, root.wall.posX, root.wall.posY) - root.ownship.heading) : 0

    // Distance to the face of the pillar, not to its centre: the centre is
    // kilometres behind the thing that kills, and a number that never reaches
    // zero before the impact teaches the pilot to distrust it.
    readonly property real wallRange: root.active ? Math.max(0, Geo.distanceFrom(root.ownship.posX, root.ownship.posY, root.wall.posX, root.wall.posY) - root.wall.radius) : 0

    implicitWidth: content.implicitWidth + 32
    implicitHeight: content.implicitHeight + 14
    visible: root.active

    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.panelBackground
        border.color: Style.theme.warn
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
            rotation: root.wallBearing
            points: [Qt.point(0, -0.5), Qt.point(0.38, 0.34), Qt.point(0, 0.14), Qt.point(-0.38, 0.34)]
            fillColor: Style.theme.warn
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("TERRAIN")
            color: Style.theme.warn
            font { pixelSize: 16; family: Style.monospace; bold: true; letterSpacing: Style.theme.capsTracking }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 KM").arg((root.wallRange / 1000).toFixed(1))
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
            duration: 240
        }

        NumberAnimation {
            from: 0.35
            to: 1
            duration: 240
        }
    }

    // The tap-sink: the warning stands over the scope's upper sector, and the
    // mark hit areas listen under the whole display — a press on it must not
    // designate whatever flies behind it.
    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
    }
}
