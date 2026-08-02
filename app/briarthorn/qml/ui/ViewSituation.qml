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

    // Heading-up turns the whole picture so ownship's nose is 12 o'clock; false
    // leaves it north-up. The rotation the track picture carries.
    property bool headingUp: true
    readonly property real viewRotation: headingUp && observer ? -observer.heading : 0

    // Symbol size in px before each classification's own scale.
    property real symbolSize: 36

    // Feature toggles — the minimap turns most of these off for a clean
    // overview. closedRings drops the range-label gap for a plain closed ring.
    property bool showInnerRing: true
    property bool showTicks: true
    property bool showRadarCone: true
    property bool showEngagements: true
    property bool showOwnship: true
    property bool showOwnshipPulse: true
    property bool showTrackLabels: true
    property bool showNorth: false
    property bool closedRings: false

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
        strokeWidth: 2
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
        strokeWidth: 2
        gapLength: root.ringGapLength
        gapAngle: 20
        range: root.projection ? root.projection.innerRangeKm : 0
        enableTicks: false
    }

    // Ownship's radar volume: a wedge off the nose (straight up, heading-up),
    // reaching the sensor's detection range, capped at the outer ring.
    ShapeSector {
        anchors.fill: parent
        visible: root.showRadarCone && root.observer
        centerX: root.centerX
        centerY: root.centerY
        angleAt: root.headingUp ? 0 : (root.observer ? root.observer.heading : 0)
        angleSpan: root.observer ? root.observer.radarFov : 0
        radius: root.observer ? Math.min(root.observer.detectionRange * root.pxPerMeter, root.outerRadius) : 0
        fillColor: Style.theme.gaugeTrack
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
        showLabels: root.showTrackLabels
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

    // Ownship, pinned at the scope centre; nose up on a heading-up scope.
    Symbol {
        visible: root.showOwnship && root.observer
        x: root.centerX - width / 2
        y: root.centerY - height / 2
        symbolSize: root.symbolSize
        noseAngle: root.headingUp ? 0 : (root.observer ? root.observer.heading : 0)
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
        readonly property real northRad: root.viewRotation * Math.PI / 180
        readonly property real seatRadius: root.outerRadius + root.northFontSize * 0.7

        visible: root.showNorth
        text: "N"
        color: Style.theme.textBright
        font.bold: true
        font.pixelSize: root.northFontSize
        x: root.centerX + Math.sin(northRad) * seatRadius - width / 2
        y: root.centerY - Math.cos(northRad) * seatRadius - height / 2
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
