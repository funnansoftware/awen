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
    id: view

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
        origin.x: view.centerX
        origin.y: view.centerY
        angle: view.viewRotation
    }

    // A world point's screen position about the observer (north-up; the
    // container rotation turns the picture heading-up).
    function sx(worldX: real): real {
        return view.centerX + (worldX - view.observer.posX) * view.pxPerMeter;
    }
    function sy(worldY: real): real {
        return view.centerY + (worldY - view.observer.posY) * view.pxPerMeter;
    }

    // The fuzing lines.
    Repeater {
        model: view.entities
        delegate: ShapeLink {
            required property Entity modelData

            readonly property Weapon armed: modelData.weapon
            readonly property bool fuzing: armed !== null && armed.state === Weapon.State.Fuzing && armed.fuzeTarget !== null

            visible: fuzing
            from: fuzing ? Qt.point(view.sx(modelData.posX), view.sy(modelData.posY)) : Qt.point(0, 0)
            to: fuzing ? Qt.point(view.sx(armed.fuzeTarget.posX), view.sy(armed.fuzeTarget.posY)) : Qt.point(0, 0)
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
        model: view.detonations
        delegate: Rectangle {
            required property Detonation modelData

            readonly property real growth: 1 - modelData.life / modelData.maxLife

            x: view.sx(modelData.worldX) - width / 2
            y: view.sy(modelData.worldY) - height / 2
            width: modelData.blastRadius * view.pxPerMeter * 2 * growth
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Style.theme.detonation
            border.width: 2
            opacity: modelData.life / modelData.maxLife
        }
    }
}
