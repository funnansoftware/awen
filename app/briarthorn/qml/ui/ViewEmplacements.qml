pragma ComponentBehavior: Bound

import QtQuick
import awen.shapes
import "../database"
import "../model"
import "../themes"

// The known emplacements: every sentry radar drawn as the beam it is actually
// sweeping — a wedge off the dish's own heading, shadow-cast behind the
// pillars exactly as ownship's cone is, so the volume turns on the scope as
// the antenna turns in the world. Two reaches nested in one beam: the faint
// span is what the set can see, the bright core what it can shoot into, and
// the fills stack so the dangerous half of a beam reads brighter without a
// second outline anywhere.
//
// Drawn from ground truth rather than the track picture, on the same argument
// the terrain layer draws pillars resolved at any range: these are fixed
// installations on a mapped arena, and a sweep a pilot cannot see is a sweep
// they cannot time. Where the dish is pointing is the whole tactical
// question, so it is the one thing this layer exists to answer.
Item {
    id: root

    // The observer at the scope centre, and the roster scanned for sentries.
    property Entity observer
    property list<Entity> entities

    // The pillars the beams are cut by, as awen.shapes' {x, y, r} rows — the
    // same set the terrain layer draws, so a bite always has its disc under it.
    property var occluders: []

    // Scope centre in item coordinates and the world-to-screen scale.
    property real centerX: width / 2
    property real centerY: height / 2
    property real pxPerMeter: 0

    // Screen rotation of the picture about the scope centre.
    property real viewRotation: 0

    // How much of the faction colour each reach is filled with. Low, and
    // lower still for the search span: a beam is a volume to route around,
    // never an alert competing with the marks that fly through it.
    property real searchAlpha: 0.07
    property real engagementAlpha: 0.11

    // When positive, a beam draws only while it fits wholly inside this pixel
    // radius — the minimap's backing disc, exactly as terrain culls.
    property real cullRadius: 0

    // The emplacements to draw. This rebuilds when the roster does — a spawn,
    // a despawn — and never per tick; a killed battery leaves the roster, so
    // its beam goes off the picture with it.
    readonly property var sites: root.entities.filter(entity => entity.sentry)

    // Whether a beam of this pixel reach fits wholly inside the mask — the
    // terrain layer's own cull rule, applied to the disc the wedge sits in.
    function fits(site: Entity, reach: real): bool {
        if (root.cullRadius <= 0)
            return true;
        if (!root.observer)
            return false;
        return Math.hypot(site.posX - root.observer.posX, site.posY - root.observer.posY) * root.pxPerMeter + reach <= root.cullRadius;
    }

    transform: Rotation {
        origin.x: root.centerX
        origin.y: root.centerY
        angle: root.viewRotation
    }

    Repeater {
        model: root.sites

        Item {
            id: emplacement

            required property Entity modelData

            // Both reaches off the entity's own priced range rather than a
            // database lookup, so a scenario that rates one battery
            // differently draws it differently.
            readonly property real searchReach: emplacement.modelData.detectionRange * root.pxPerMeter
            readonly property real engagementReach: GameRules.sentryFireRangeFor(emplacement.modelData.detectionRange) * root.pxPerMeter
            readonly property real screenX: root.observer ? root.centerX + (emplacement.modelData.posX - root.observer.posX) * root.pxPerMeter : 0
            readonly property real screenY: root.observer ? root.centerY + (emplacement.modelData.posY - root.observer.posY) * root.pxPerMeter : 0

            readonly property color beamColor: {
                switch (emplacement.modelData.side) {
                case Side.Kind.Hostile:
                    return Style.theme.factionHostile;
                case Side.Kind.Friendly:
                case Side.Kind.Ownship:
                    return Style.theme.factionFriendly;
                default:
                    return Style.theme.factionUnknown;
                }
            }

            // What cuts THIS battery's beam: the pieces its own side does not
            // see through. Its screens drop out, so the beam sweeps visibly
            // straight through ground that bites the player's own cone — the
            // asymmetry is on the scope rather than in a rule nobody sees.
            readonly property var beamOccluders: root.occluders.filter(row => row.transparentTo !== emplacement.modelData.side)

            visible: root.observer !== null

            // The span it searches: where a craft is found and followed.
            Loader {
                anchors.fill: parent
                active: emplacement.searchReach > 0 && root.fits(emplacement.modelData, emplacement.searchReach)

                sourceComponent: ShapeSectorOccluded {
                    centerX: emplacement.screenX
                    centerY: emplacement.screenY
                    angleAt: emplacement.modelData.heading
                    angleSpan: emplacement.modelData.radarFov
                    radius: emplacement.searchReach
                    sourceX: emplacement.modelData.posX
                    sourceY: emplacement.modelData.posY
                    positionScale: root.pxPerMeter
                    occluders: emplacement.beamOccluders
                    fillColor: Qt.alpha(emplacement.beamColor, root.searchAlpha)
                }
            }

            // The core it shoots into, laid over the span so the two fills
            // stack: the brighter half of the beam is the half that kills.
            Loader {
                anchors.fill: parent
                active: emplacement.engagementReach > 0 && root.fits(emplacement.modelData, emplacement.engagementReach)

                sourceComponent: ShapeSectorOccluded {
                    centerX: emplacement.screenX
                    centerY: emplacement.screenY
                    angleAt: emplacement.modelData.heading
                    angleSpan: emplacement.modelData.radarFov
                    radius: emplacement.engagementReach
                    sourceX: emplacement.modelData.posX
                    sourceY: emplacement.modelData.posY
                    positionScale: root.pxPerMeter
                    occluders: emplacement.beamOccluders
                    fillColor: Qt.alpha(emplacement.beamColor, root.engagementAlpha)
                }
            }
        }
    }
}
