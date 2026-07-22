import QtQuick
import "../model"

// Renders an observer's track picture: each Track plots at its azimuth and
// range in the observer's heading-up frame, scaled by the projection's
// metres-to-pixels factor about the scope centre.
Item {
    id: view

    // The track picture and the observer whose frame orients it.
    property list<Track> tracks
    required property Entity observer

    // Scope centre in item coordinates and the world-to-screen scale.
    property real centerX: width / 2
    property real centerY: height / 2
    property real pxPerMeter: 0

    Repeater {
        model: view.tracks
        delegate: Symbol {
            required property Track modelData

            readonly property real screenAngle: (modelData.azimuth - view.observer.heading) * Math.PI / 180
            readonly property real screenRange: modelData.range * view.pxPerMeter

            x: view.centerX + Math.sin(screenAngle) * screenRange - width / 2
            y: view.centerY - Math.cos(screenAngle) * screenRange - height / 2
            noseAngle: modelData.heading - view.observer.heading
            classification: modelData.classification
            side: modelData.side
            label: modelData.classification === Classification.Kind.Unknown ? "" : modelData.contactId
        }
    }
}
