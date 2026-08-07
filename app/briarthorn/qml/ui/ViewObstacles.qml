pragma ComponentBehavior: Bound

import QtQuick
import "../model"
import "../themes"

// The arena geometry: every pillar as a disc at true world scale about the
// observer, terrain-brown under the air picture. Ground truth rather than a
// sensor product — the arena is mapped, so it draws resolved at any range.
Item {
    id: root

    // The observer at the scope centre.
    property Entity observer

    // The pillars to draw.
    property list<Obstacle> obstacles

    // Scope centre in item coordinates and the world-to-screen scale.
    property real centerX: width / 2
    property real centerY: height / 2
    property real pxPerMeter: 0

    // Screen rotation of the picture about the scope centre.
    property real viewRotation: 0

    // Rim stroke width, matching the scope's line weight.
    property real strokeWidth: 2

    // When positive, a pillar draws only while it fits wholly inside this
    // pixel radius — the minimap's backing disc, so terrain never spills
    // past that mask onto the scope beneath.
    property real cullRadius: 0

    transform: Rotation {
        origin.x: root.centerX
        origin.y: root.centerY
        angle: root.viewRotation
    }

    Repeater {
        model: root.obstacles

        Rectangle {
            id: pillar

            required property Obstacle modelData

            readonly property real edge: pillar.modelData.radius * root.pxPerMeter
            readonly property real screenX: root.observer ? root.centerX + (pillar.modelData.posX - root.observer.posX) * root.pxPerMeter : 0
            readonly property real screenY: root.observer ? root.centerY + (pillar.modelData.posY - root.observer.posY) * root.pxPerMeter : 0

            visible: root.cullRadius <= 0 || Math.hypot(pillar.screenX - root.centerX, pillar.screenY - root.centerY) + pillar.edge <= root.cullRadius
            x: pillar.screenX - pillar.edge
            y: pillar.screenY - pillar.edge
            width: pillar.edge * 2
            height: width
            radius: width / 2
            color: Style.theme.terrainFill
            border.color: Style.theme.terrain
            border.width: root.strokeWidth
        }
    }
}
