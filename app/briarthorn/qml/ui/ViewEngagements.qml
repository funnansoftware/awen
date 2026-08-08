pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import awen.shapes
import "../model"
import "../themes"

// The engagement overlay: a crawling line from each guided round to whatever
// its seeker is holding, a dashed line from each fuzing missile to the entity
// its fuze tripped on, and every blast as a ring expanding to true scale while
// it fades. Ground-truth world positions plotted about the observer and rotated
// as one picture, exactly like ViewTracks.
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

    // The fuzing missiles alone: delegates are Shapes, so modelling every
    // entity would rebuild them all on each spawn — and the roster churns
    // constantly once missiles and decoys fly. The state reads inside the
    // filter keep it live, so a fuze tripping re-evaluates the list.
    readonly property list<Entity> fuzing: entities.filter(e => e.weapon !== null && e.weapon.state === Weapon.State.Fuzing)

    // Every guided round aloft, whatever it is holding right now. Filtering on
    // the lock instead would tear a delegate down and stand a new one up each
    // time a seeker re-homed — the one moment the link has to survive and swing
    // — so this list turns over only as rounds spawn and despawn, and the
    // delegate shows and hides itself.
    readonly property list<Entity> seekers: entities.filter(e => e.weapon !== null && e.weapon.def !== null && e.weapon.def.guided)

    // The seeker links, under the fuzing lines: each guided round tied to the
    // return it is homing on this instant, dashes crawling toward it. The link
    // is drawn only while the seeker holds something, so it goes out the moment
    // a round is blinded and swings across the moment it re-homes — which is
    // how a decoy reads on the scope, the line jumping off the craft onto the
    // flare that took the shot instead. Every round's link is drawn, the
    // hostile's included — what the round hunting the pilot has settled on is
    // the one thing they most need to see.
    Repeater {
        model: root.seekers

        ShapeLink {
            id: seeker

            // Dash geometry in ShapeLink's stroke-width units, and the crawl
            // below walks one whole pattern per cycle toward the target — so
            // the flow reads at the same speed on a link of any length.
            readonly property real dashOn: 4
            readonly property real dashGap: 3

            required property Entity modelData

            readonly property Weapon round: seeker.modelData.weapon
            readonly property Entity locked: seeker.round !== null && seeker.round.state === Weapon.State.Flying ? seeker.round.target : null
            readonly property bool tracking: seeker.locked !== null

            visible: seeker.tracking
            from: seeker.tracking ? Qt.point(root.sx(seeker.modelData.posX), root.sy(seeker.modelData.posY)) : Qt.point(0, 0)
            to: seeker.tracking ? Qt.point(root.sx(seeker.locked.posX), root.sy(seeker.locked.posY)) : Qt.point(0, 0)
            fromControl: from
            toControl: to
            strokeColor: root.sideColor(seeker.modelData.side)
            strokeWidth: 1.5
            strokeStyle: ShapePath.DashLine
            dashPattern: [seeker.dashOn, seeker.dashGap]
            glowColor: Qt.alpha(seeker.strokeColor, 0.15)
            arrowhead: true
            arrowSize: 7

            NumberAnimation on dashOffset {
                running: seeker.tracking
                loops: Animation.Infinite
                from: seeker.dashOn + seeker.dashGap
                to: 0
                duration: 480
            }
        }
    }

    // The fuzing lines.
    Repeater {
        model: root.fuzing

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

    // A round's link takes its launcher's faction colour, so the shot the pilot
    // sent and the one hunting them read apart at a glance.
    function sideColor(side: int): color {
        switch (side) {
        case Side.Kind.Ownship:
            return Style.theme.factionOwnship;
        case Side.Kind.Friendly:
            return Style.theme.factionFriendly;
        case Side.Kind.Neutral:
            return Style.theme.factionNeutral;
        case Side.Kind.Hostile:
            return Style.theme.factionHostile;
        default:
            return Style.theme.factionUnknown;
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
