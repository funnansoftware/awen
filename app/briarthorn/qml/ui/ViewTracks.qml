pragma ComponentBehavior: Bound

import QtQuick
import "../database"
import "../model"

// Renders a track picture: each Track plots at its true azimuth and range
// about the scope centre, scaled by the projection's metres-to-pixels
// factor. The whole picture turns as one scene-graph rotation — bind
// viewRotation to -observer.heading for a heading-up scope, leave it 0 for
// north-up — so delegates never apply an observer delta themselves.
Item {
    id: root

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

    // When positive, off-scale contacts clamp to this pixel radius (the outer
    // ring) instead of plotting beyond it, so ranging in seats a contact that
    // no longer fits at the edge rather than losing it off the display.
    property real clampRadius: 0

    // How far past that radius a clamped symbol is seated, in half-symbol
    // extents: 1 stands the whole symbol clear of the radius, 0 puts the radius
    // through its centre, and more pushes it further out. Measured off each
    // symbol's own size, so a mark drawn small seats as close as a large one.
    property real clampMargin: 1

    transform: Rotation {
        origin.x: root.centerX
        origin.y: root.centerY
        angle: root.viewRotation
    }

    Repeater {
        model: root.tracks

        Loader {
            id: mark
            required property Track modelData

            readonly property real azimuthRad: modelData.azimuth * Math.PI / 180
            readonly property real trueRange: modelData.range * root.pxPerMeter

            // Beyond the scale, and so clamped: the symbol steps out to its
            // seat past the clamp radius rather than plotting where it truly
            // is. A contact still on the scale is never pushed anywhere.
            readonly property bool offScale: root.clampRadius > 0 && mark.trueRange > root.clampRadius
            readonly property real screenRange: mark.offScale ? root.clampRadius + root.clampMargin * mark.height / 2 : mark.trueRange

            readonly property Component symbolMark: Component {
                Symbol {
                    symbolSize: root.symbolSize
                    noseAngle: mark.modelData.heading
                    viewRotation: root.viewRotation
                    classification: mark.modelData.classification
                    side: mark.modelData.side
                    showLabel: root.showLabels
                    label: mark.modelData.classification === Classification.Kind.Unknown ? "" : mark.modelData.contactId
                }
            }

            readonly property Component flareMark: Component {
                SymbolFlare {
                    symbolSize: root.symbolSize
                }
            }

            x: root.centerX + Math.sin(azimuthRad) * screenRange - width / 2
            y: root.centerY - Math.cos(azimuthRad) * screenRange - height / 2

            // A contact classified as a countermeasure plots as a burning
            // flare, no faction symbol or label — briardart skips the symbol
            // the same way. Everything else keeps the classification mark.
            sourceComponent: mark.modelData.classification === Classification.Kind.Decoy ? mark.flareMark : mark.symbolMark
        }
    }
}
