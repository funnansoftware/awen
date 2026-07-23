import QtQuick
import "../model"

// Renders a track picture: each Track plots at its true azimuth and range
// about the scope centre, scaled by the projection's metres-to-pixels
// factor. The whole picture turns as one scene-graph rotation — bind
// viewRotation to -observer.heading for a heading-up scope, leave it 0 for
// north-up — so delegates never apply an observer delta themselves.
Item {
    id: view

    property list<Track> tracks

    // Scope centre in item coordinates and the world-to-screen scale.
    property real centerX: width / 2
    property real centerY: height / 2
    property real pxPerMeter: 0

    // Screen rotation of the picture about the scope centre.
    property real viewRotation: 0

    // Symbol size in px before the classification's own scale.
    property real symbolSize: 36

    // Whether track symbols carry their contact-id labels.
    property bool showLabels: true

    // When positive, off-scale contacts pin to this pixel radius (the outer
    // rim) instead of plotting beyond it — the minimap's overview behaviour.
    property real clampRadius: 0

    transform: Rotation {
        origin.x: view.centerX
        origin.y: view.centerY
        angle: view.viewRotation
    }

    Repeater {
        model: view.tracks
        delegate: Symbol {
            required property Track modelData

            readonly property real azimuthRad: modelData.azimuth * Math.PI / 180
            readonly property real trueRange: modelData.range * view.pxPerMeter
            // Clamp beyond-scale contacts to the rim when asked, so they read
            // at the ring edge rather than off the display.
            readonly property real screenRange: view.clampRadius > 0 ? Math.min(trueRange, view.clampRadius) : trueRange

            x: view.centerX + Math.sin(azimuthRad) * screenRange - width / 2
            y: view.centerY - Math.cos(azimuthRad) * screenRange - height / 2
            symbolSize: view.symbolSize
            noseAngle: modelData.heading
            viewRotation: view.viewRotation
            classification: modelData.classification
            side: modelData.side
            showLabel: view.showLabels
            label: modelData.classification === Classification.Kind.Unknown ? "" : modelData.contactId
        }
    }
}
