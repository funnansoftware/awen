import QtQuick
import awen.shapes
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
    id: view

    // Shared display projection: the ring spans and the metres-to-pixels scale.
    property RangeProjection projection

    // The observer at the scope centre: its heading drives the heading-up
    // rotation, its radar FOV + sensor range the cone, its class + side the
    // ownship mark.
    property Entity observer

    // The contact picture, plotted at each track's azimuth and range.
    property list<Track> tracks

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
    property bool showOwnship: true
    property bool showOwnshipPulse: true
    property bool showTrackLabels: true
    property bool showNorth: false
    property bool closedRings: false

    // The range-label gap arc length, in px; 0 (closedRings) draws closed rings.
    readonly property real ringGapLength: closedRings ? 0 : Math.max(28, outerRadius * 0.1)

    // Compact-overview plumbing. rimClamp pins off-scale contacts to the outer
    // rim; backgroundColor paints an opaque disc behind the picture so it reads
    // over whatever sits behind it. The disc reaches a symbol past the outer
    // ring, so a rim-pinned mark can never spill past it — the mask that keeps
    // objects outside the view from rendering under the minimap (briardart clips
    // to this same disc, then pins off-scale tracks to its rim).
    property bool rimClamp: false
    property color backgroundColor: "transparent"
    readonly property real discRadius: outerRadius + symbolSize

    // The opaque backing disc (minimap only; transparent by default). A circle
    // centred on the scope, so the box's corners stay clear.
    Rectangle {
        visible: view.backgroundColor.a > 0
        x: view.centerX - width / 2
        y: view.centerY - height / 2
        width: view.discRadius * 2
        height: width
        radius: width / 2
        color: view.backgroundColor
    }

    // Outer range ring: carries the bearing ticks and its span label, the ticks
    // offset to keep true bearings on the heading-up scope.
    RangeRing {
        anchors.fill: parent
        centerX: view.centerX
        centerY: view.centerY
        radius: view.outerRadius
        strokeWidth: 2
        gapLength: view.ringGapLength
        gapAngle: 20
        range: view.projection ? view.projection.rangeKm : 0
        enableTicks: view.showTicks
        tickOffset: view.viewRotation
    }

    // Inner ring: half the span, label only.
    RangeRing {
        anchors.fill: parent
        visible: view.showInnerRing
        centerX: view.centerX
        centerY: view.centerY
        radius: view.outerRadius / 2
        strokeWidth: 2
        gapLength: view.ringGapLength
        gapAngle: 20
        range: view.projection ? view.projection.innerRangeKm : 0
        enableTicks: false
    }

    // Ownship's radar volume: a wedge off the nose (straight up, heading-up),
    // reaching the sensor's detection range, capped at the outer ring.
    ShapeSector {
        anchors.fill: parent
        visible: view.showRadarCone && view.observer
        centerX: view.centerX
        centerY: view.centerY
        angleAt: view.headingUp ? 0 : (view.observer ? view.observer.heading : 0)
        angleSpan: view.observer ? view.observer.radarFov : 0
        radius: view.observer ? Math.min(view.observer.sensor * view.pxPerMeter, view.outerRadius) : 0
        fillColor: Style.theme.gaugeTrack
    }

    // The track picture: every contact at its azimuth and range, the whole
    // picture rotated into the heading-up frame; rim-clamped for the minimap.
    ViewTracks {
        anchors.fill: parent
        centerX: view.centerX
        centerY: view.centerY
        pxPerMeter: view.pxPerMeter
        viewRotation: view.viewRotation
        tracks: view.tracks
        symbolSize: view.symbolSize
        showLabels: view.showTrackLabels
        clampRadius: view.rimClamp ? view.outerRadius : 0
    }

    // Ownship, pinned at the scope centre; nose up on a heading-up scope.
    Symbol {
        visible: view.showOwnship && view.observer
        x: view.centerX - width / 2
        y: view.centerY - height / 2
        symbolSize: view.symbolSize
        noseAngle: view.headingUp ? 0 : (view.observer ? view.observer.heading : 0)
        classification: view.observer ? view.observer.classification : Classification.Kind.Unknown
        side: view.observer ? view.observer.side : Side.Kind.Unknown
        showLabel: false
    }

    // North marker: an 'N' seated just outside the rim at the north bearing,
    // sweeping round the rim as ownship turns (heading-up). The minimap's stand-in
    // for the suppressed bearing ticks.
    Text {
        visible: view.showNorth
        text: "N"
        color: Style.theme.textBright
        font.bold: true
        font.pixelSize: Math.max(9, view.outerRadius * 0.16)

        // North (true bearing 0) sits at screen angle viewRotation on a
        // heading-up scope; seat the label a little past the ring.
        readonly property real northRad: view.viewRotation * Math.PI / 180
        readonly property real seatRadius: view.outerRadius + font.pixelSize * 0.7
        x: view.centerX + Math.sin(northRad) * seatRadius - width / 2
        y: view.centerY - Math.cos(northRad) * seatRadius - height / 2
    }

    // The pulsing acquisition ring marking ownship, fixed at the scope centre.
    Rectangle {
        visible: view.showOwnshipPulse
        x: view.centerX - width / 2
        y: view.centerY - height / 2
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
