import QtQuick
import awen.shapes
import "../database"
import "../model"
import "../themes"

// A tactical situation display: the range rings, ownship's radar cone, the
// track picture and ownship at the scope centre, composed as one configurable
// Item. The same component serves the full-size attack scope (see
// ViewSituationAttack) and the corner minimap — features toggle off and the
// picture masks to a disc for the compact overview. Both instances share one
// RangeProjection, so ranging in/out moves them together. Ports briardart's
// ScopeComponent (render/scope_component.dart), the Flame counterpart of this.
Item {
    id: root

    // Shared display projection: the ring spans and the metres-to-pixels scale.
    property RangeProjection projection

    // The observer at the scope centre: its heading drives the heading-up
    // rotation, its radar FOV + sensor range the cone, its class + side the
    // ownship mark.
    property Entity observer

    // The contact picture, plotted at each track's azimuth and range.
    property list<Track> tracks

    // Engagement truth for the overlay: the world's entities (scanned for
    // fuzing missiles) and the blasts in progress. Optional — leave empty
    // (and showEngagements off) for a clean overview.
    property list<Entity> entities
    property list<Detonation> detonations

    // The arena's pillars, drawn as terrain under the air picture.
    property list<Obstacle> obstacles

    // The same pillars as plain disc rows for awen.shapes' shadow cast, held
    // to the ones the terrain layer draws so a bite always has its disc under
    // it. Unmasked, that is every pillar and the rows rebuild only when a
    // scenario swaps its arena; a masked scope re-culls as ownship moves.
    readonly property var occluderRows: {
        const rows = [];
        for (let i = 0; i < obstacles.length; ++i) {
            const pillar = obstacles[i];
            if (terrain.draws(pillar.posX, pillar.posY, pillar.radius))
                rows.push({
                    x: pillar.posX,
                    y: pillar.posY,
                    r: pillar.radius
                });
        }
        return rows;
    }

    // Geometry. The outer ring's radius is a fraction of the short side; the
    // centre drops by verticalShift (and slides by horizontalShift) so the
    // attack scope can push ownship down and crop the rear off the bottom edge.
    property real radiusFraction: 0.4
    property real verticalShift: 0
    property real horizontalShift: 0

    readonly property real shortSide: Math.min(width, height)
    readonly property real outerRadius: shortSide * radiusFraction
    readonly property real centerX: width * (0.5 + horizontalShift)
    readonly property real centerY: height * (0.5 + verticalShift)
    readonly property real pxPerMeter: projection ? projection.pixelsPerMeter(outerRadius) : 0

    // The armed weapon's launch envelope, in metres of reach: the volume a
    // contact has to sit inside for the shot to lock on and arrive. Drawn only
    // while the pilot is holding a weapon armed — a reach of 0 is the
    // disarmed scope and paints nothing — and painted valid the moment the
    // seeker has a return, caution-coloured and breathing while it has none.
    // This is the scope's own answer to "why will this not fire".
    property real armedReach: 0
    property bool armedValid: false

    // The pilot's designated contact, by track id, and the contact a guided
    // launch would take right now. The cursor stands on the first and turns
    // its latched colour where the second agrees; both empty mark nothing.
    property string selectedContact: ""
    property string shootableContact: ""

    // Whether a tap on a selectable mark designates it; the minimap and the
    // menu backdrop leave it off and carry no handlers at all.
    property bool selectionEnabled: false

    // A tap on a selectable mark, by track id, forwarded off the track layer;
    // trackTouched rides with it when the tap came from a touchscreen.
    signal trackTapped(string contactId)
    signal trackTouched

    // Heading-up turns the whole picture so ownship's nose is 12 o'clock; false
    // leaves it north-up. The rotation the track picture carries.
    property bool headingUp: true
    readonly property real viewRotation: headingUp && observer ? -observer.heading : 0

    // Symbol size in px before each classification's own scale.
    property real symbolSize: 36

    // Line weights: the rings', and the marks' outline stroke, which starts
    // at the rings' weight so the whole scope draws with one line.
    property real ringStrokeWidth: 2
    property real symbolStrokeWidth: ringStrokeWidth

    // Feature toggles — the minimap turns most of these off for a clean
    // overview. closedRings drops the range-label gap for a plain closed ring.
    property bool showInnerRing: true
    property bool showTicks: true
    property bool showRadarCone: true
    property bool showTrails: true
    property bool showEngagements: true
    property bool showOwnship: true
    property bool showOwnshipPulse: true
    property bool showTrackLabels: true
    property bool showTrackHealth: true
    property bool showTrackRanges: true
    property bool showNorth: false
    property bool closedRings: false

    // Whether the wake layer's sampling clock runs; bind it to the sim so a
    // paused game freezes its trails rather than contracting them.
    property bool trailsRunning: true

    // The range-label gap arc length, in px; 0 (closedRings) draws closed rings.
    readonly property real ringGapLength: closedRings ? 0 : Math.max(28, outerRadius * 0.1)

    // North-marker size (shared with the backing disc below), floored so the
    // 'N' stays legible when the map is small.
    readonly property real northFontSize: Math.max(9, outerRadius * 0.16)

    // Off-scale contacts clamp into the gutter — the band just outside the
    // outer ring — instead of plotting past it, so ranging the scope in seats a
    // contact that no longer fits at the edge rather than losing it off the
    // display. gutterClampMargin is how far into the gutter one sits, in
    // half-symbol extents: 1 stands the whole symbol clear of the ring, 0 puts
    // the ring through its centre.
    property bool gutterClamp: true
    property real gutterClampMargin: 1

    // Compact-overview plumbing: backgroundColor paints an opaque disc behind
    // the picture so it reads over whatever sits behind it. The disc reaches
    // just past the outer ring — to the north marker's outer edge when shown,
    // else across the gutter, far enough to seat a clamped symbol standing its
    // own margin plus its own half-extent out — and both margins scale with the
    // map, so the disc no longer bloats past the picture as the minimap
    // shrinks. This is the mask that keeps objects outside the view from
    // rendering under the minimap (briardart clips to this same disc, then pins
    // off-scale tracks to its rim).
    property color backgroundColor: "transparent"
    readonly property real discRadius: outerRadius + Math.max(showNorth ? northFontSize * 1.15 : 0, symbolSize * (gutterClampMargin + 1) / 2)

    // The opaque backing disc (minimap only; transparent by default). A circle
    // centred on the scope, so the box's corners stay clear.
    Rectangle {
        visible: root.backgroundColor.a > 0
        x: root.centerX - width / 2
        y: root.centerY - height / 2
        width: root.discRadius * 2
        height: width
        radius: width / 2
        color: root.backgroundColor
    }

    // Outer range ring: carries the bearing ticks and its span label, the ticks
    // offset to keep true bearings on the heading-up scope.
    RangeRing {
        anchors.fill: parent
        centerX: root.centerX
        centerY: root.centerY
        radius: root.outerRadius
        strokeWidth: root.ringStrokeWidth
        gapLength: root.ringGapLength
        gapAngle: 20
        range: root.projection ? root.projection.rangeKm : 0
        enableTicks: root.showTicks
        tickOffset: root.viewRotation
    }

    // Inner ring: half the span, label only.
    RangeRing {
        anchors.fill: parent
        visible: root.showInnerRing
        centerX: root.centerX
        centerY: root.centerY
        radius: root.outerRadius / 2
        strokeWidth: root.ringStrokeWidth
        gapLength: root.ringGapLength
        gapAngle: 20
        range: root.projection ? root.projection.innerRangeKm : 0
        enableTicks: false
    }

    // Ownship's commanded radar volume, faint: where the antenna points even
    // where terrain masks it. A wedge off the nose (straight up, heading-up),
    // reaching the sensor's detection range, capped at the outer ring.
    ShapeSector {
        anchors.fill: parent
        visible: root.showRadarCone && root.observer
        centerX: root.centerX
        centerY: root.centerY
        angleAt: root.headingUp ? 0 : (root.observer ? root.observer.heading : 0)
        angleSpan: root.observer ? root.observer.radarFov : 0
        radius: root.observer ? Math.min(root.observer.detectionRange * root.pxPerMeter, root.outerRadius) : 0
        fillColor: Qt.alpha(Style.theme.gaugeTrack, 0.035)
    }

    // What the radar actually sees: the same wedge shadow-cast behind the
    // pillars, computed in world bearings and turned by the rotation
    // ViewObstacles carries, so every bite lands exactly on its drawn disc.
    ShapeSectorOccluded {
        anchors.fill: parent
        visible: root.showRadarCone && root.observer
        centerX: root.centerX
        centerY: root.centerY
        angleAt: root.observer ? root.observer.heading : 0
        angleSpan: root.observer ? root.observer.radarFov : 0
        radius: root.observer ? Math.min(root.observer.detectionRange * root.pxPerMeter, root.outerRadius) : 0
        sourceX: root.observer ? root.observer.posX : 0
        sourceY: root.observer ? root.observer.posY : 0
        positionScale: root.pxPerMeter
        occluders: root.occluderRows
        fillColor: Style.theme.gaugeTrack

        transform: Rotation {
            origin.x: root.centerX
            origin.y: root.centerY
            angle: root.viewRotation
        }
    }

    // The armed weapon's launch envelope, over the radar volume: the same
    // shadow-cast wedge drawn at the round's own reach, so a pillar's shadow
    // shows the shot it denies exactly as it shows the radar's blind arc, and
    // a contact simply too far out plots visibly beyond the rim. Painted valid
    // once the seeker holds a return and breathing in the caution colour while
    // it holds none.
    ShapeSectorOccluded {
        id: envelope

        // The breathing, read only while the shot is invalid — a valid
        // envelope holds steady, so the property is never bound over the
        // animation driving it.
        property real pulse: 1

        anchors.fill: parent
        visible: root.armedReach > 0 && root.observer
        centerX: root.centerX
        centerY: root.centerY
        angleAt: root.observer ? root.observer.heading : 0
        angleSpan: root.observer ? root.observer.radarFov : 0
        radius: root.observer ? Math.min(root.armedReach * root.pxPerMeter, root.outerRadius) : 0
        sourceX: root.observer ? root.observer.posX : 0
        sourceY: root.observer ? root.observer.posY : 0
        positionScale: root.pxPerMeter
        occluders: root.occluderRows
        fillColor: Qt.alpha(root.armedValid ? Style.theme.armValid : Style.theme.armInvalid, 0.13)
        strokeColor: root.armedValid ? Style.theme.armValid : Style.theme.armInvalid
        strokeWidth: root.ringStrokeWidth
        opacity: root.armedValid ? 1 : envelope.pulse

        transform: Rotation {
            origin.x: root.centerX
            origin.y: root.centerY
            angle: root.viewRotation
        }

        SequentialAnimation on pulse {
            running: envelope.visible && !root.armedValid
            loops: Animation.Infinite

            NumberAnimation { from: 1; to: 0.25; duration: 300 }
            NumberAnimation { from: 0.25; to: 1; duration: 300 }
        }
    }

    // The arena terrain, over the rings and cone but under everything that
    // flies. Culled to the backing disc where one masks the picture, so a
    // pillar never spills past the minimap onto the scope beneath.
    ViewObstacles {
        id: terrain

        anchors.fill: parent
        observer: root.observer
        obstacles: root.obstacles
        centerX: root.centerX
        centerY: root.centerY
        pxPerMeter: root.pxPerMeter
        viewRotation: root.viewRotation
        strokeWidth: root.ringStrokeWidth
        cullRadius: root.backgroundColor.a > 0 ? root.discRadius : 0
    }

    // The motion wakes, under the marks they trail: each object's recent
    // world track as fading dots, ownship's about the centre and each
    // contact's about its plotted mark.
    ViewTrails {
        anchors.fill: parent
        visible: root.showTrails
        observer: root.observer
        tracks: root.tracks
        centerX: root.centerX
        centerY: root.centerY
        pxPerMeter: root.pxPerMeter
        viewRotation: root.viewRotation
        running: root.showTrails && root.trailsRunning
        clampRadius: root.gutterClamp ? root.outerRadius : 0
    }

    // The track picture: every contact at its azimuth and range, the whole
    // picture rotated into the heading-up frame, off-scale contacts seated in
    // the gutter.
    ViewTracks {
        anchors.fill: parent
        centerX: root.centerX
        centerY: root.centerY
        pxPerMeter: root.pxPerMeter
        viewRotation: root.viewRotation
        tracks: root.tracks
        symbolSize: root.symbolSize
        symbolStrokeWidth: root.symbolStrokeWidth
        selectedContact: root.selectedContact
        shootableContact: root.shootableContact
        selectionEnabled: root.selectionEnabled
        onTrackTapped: contactId => root.trackTapped(contactId)
        onTrackTouched: root.trackTouched()
        showLabels: root.showTrackLabels
        showHealth: root.showTrackHealth
        showRanges: root.showTrackRanges
        clampRadius: root.gutterClamp ? root.outerRadius : 0
        clampMargin: root.gutterClampMargin
    }

    // Fuzing lines and blast rings, over the tracks in the same rotated
    // observer frame.
    ViewEngagements {
        anchors.fill: parent
        visible: root.showEngagements
        observer: root.observer
        entities: root.entities
        detonations: root.detonations
        centerX: root.centerX
        centerY: root.centerY
        pxPerMeter: root.pxPerMeter
        viewRotation: root.viewRotation
    }

    // Ownship, pinned at the scope centre; nose up on a heading-up scope. It
    // holds its place through a turn, so its bank is the one thing on the
    // scope that shows the turn as the pilot's own — the picture swinging
    // round is what everyone else's looks like.
    Symbol {
        visible: root.showOwnship && root.observer
        x: root.centerX - width / 2
        y: root.centerY - height / 2
        symbolSize: root.symbolSize
        strokeWidth: root.symbolStrokeWidth
        noseAngle: root.headingUp ? 0 : (root.observer ? root.observer.heading : 0)
        bankAngle: root.observer ? root.observer.bank : 0
        classification: root.observer ? root.observer.classification : Classification.Kind.Unknown
        side: root.observer ? root.observer.side : Side.Kind.Unknown
        showLabel: false
    }

    // North marker: an 'N' seated just outside the rim at the north bearing,
    // sweeping round the rim as ownship turns (heading-up). The minimap's stand-in
    // for the suppressed bearing ticks.
    Text {
        // North (true bearing 0) sits at screen angle viewRotation on a
        // heading-up scope; seat the label a little past the ring.
        readonly property real seatRadius: root.outerRadius + root.northFontSize * 0.7

        visible: root.showNorth
        text: "N"
        color: Style.theme.textBright
        font { bold: true; pixelSize: root.northFontSize; family: Style.monospace }
        x: root.centerX + Geo.offsetX(root.viewRotation, seatRadius) - width / 2
        y: root.centerY + Geo.offsetY(root.viewRotation, seatRadius) - height / 2
    }

    // The pulsing acquisition ring marking ownship, fixed at the scope centre.
    Rectangle {
        visible: root.showOwnshipPulse
        x: root.centerX - width / 2
        y: root.centerY - height / 2
        width: 48
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Style.theme.factionOwnship
        border.width: 2

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.4
                to: 0.0
                duration: 1500
                easing.type: Easing.OutQuad
            }
            PauseAnimation {
                duration: 250
            }
        }
        SequentialAnimation on scale {
            loops: Animation.Infinite
            NumberAnimation {
                from: 0.5
                to: 1.8
                duration: 1500
                easing.type: Easing.OutQuad
            }
            PauseAnimation {
                duration: 250
            }
        }
    }
}
