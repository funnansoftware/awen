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
            readonly property real screenRange: modelData.range * view.pxPerMeter

            x: view.centerX + Math.sin(azimuthRad) * screenRange - width / 2
            y: view.centerY - Math.cos(azimuthRad) * screenRange - height / 2
            noseAngle: modelData.heading
            viewRotation: view.viewRotation
            classification: modelData.classification
            side: modelData.side
            label: modelData.classification === Classification.Kind.Unknown ? "" : modelData.contactId
        }
    }
}
