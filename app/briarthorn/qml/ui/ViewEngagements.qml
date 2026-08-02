pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import awen.shapes
import "../model"
import "../themes"

// The engagement overlay: a dashed line from each fuzing missile to the
// entity its fuze tripped on, and every blast as a ring expanding to true
// scale while it fades. Ground-truth world positions plotted about the
// observer and rotated as one picture, exactly like ViewTracks.
Item {
    id: root

    // The observer at the scope centre.
    property Entity observer

    // The world's entities, scanned for fuzing missiles.
    property list<Entity> entities

    // Blasts in progress, from the weapon engine.
    property list<Detonation> detonations

    // Scope centre in item coordinates and the world-to-screen scale.
    property real centerX: width / 2
    property real centerY: height / 2
    property real pxPerMeter: 0

    // Screen rotation of the picture about the scope centre.
    property real viewRotation: 0

    transform: Rotation {
        origin.x: root.centerX
        origin.y: root.centerY
        angle: root.viewRotation
    }

    // The fuzing lines.
    Repeater {
        model: root.entities

        ShapeLink {
            required property Entity modelData

            readonly property Weapon armed: modelData.weapon
            readonly property bool fuzing: armed !== null && armed.state === Weapon.State.Fuzing && armed.fuzeTarget !== null

            visible: fuzing
            from: fuzing ? Qt.point(root.sx(modelData.posX), root.sy(modelData.posY)) : Qt.point(0, 0)
            to: fuzing ? Qt.point(root.sx(armed.fuzeTarget.posX), root.sy(armed.fuzeTarget.posY)) : Qt.point(0, 0)
            fromControl: from
            toControl: to
            strokeColor: Style.theme.detonation
            strokeWidth: 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [3, 2]
        }
    }

    // The blast rings: expanding toward blastRadius as life runs down,
    // fading with the remaining fraction.
    Repeater {
        model: root.detonations

        Rectangle {
            required property Detonation modelData

            readonly property real growth: 1 - modelData.life / modelData.maxLife

            x: root.sx(modelData.worldX) - width / 2
            y: root.sy(modelData.worldY) - height / 2
            width: modelData.blastRadius * root.pxPerMeter * 2 * growth
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Style.theme.detonation
            border.width: 2
            opacity: modelData.life / modelData.maxLife
        }
    }

    // A world point's screen position about the observer (north-up; the
    // container rotation turns the picture heading-up).
    function sx(worldX: real): real {
        return root.centerX + (worldX - root.observer.posX) * root.pxPerMeter;
    }
    function sy(worldY: real): real {
        return root.centerY + (worldY - root.observer.posY) * root.pxPerMeter;
    }
}
