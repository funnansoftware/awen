pragma ComponentBehavior: Bound

import QtQuick
import "../database"
import "../model"

// Renders a track picture: each Track plots at its true azimuth and range
// about the scope centre, scaled by the projection's metres-to-pixels
// factor. The whole picture turns as one scene-graph rotation — bind
// viewRotation to -observer.heading for a heading-up scope, leave it 0 for
// north-up — so delegates never apply an observer delta themselves.
// Marks are keyed per contact and pruned with the track rather than repeated
// over the list: the roster churns with every launch and burnout, and
// rebuilding a Shapes symbol per surviving contact each time stutters the
// whole scene.
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

    // Outline stroke width each mark draws with.
    property real symbolStrokeWidth: 2

    // Whether track symbols carry their contact-id labels.
    property bool showLabels: true

    // Whether track symbols carry their hull gauges. Only kinds whose database
    // row asks for one ever draw it, so this just suppresses the lot — the
    // minimap wants the plot, not the condition of everything on it.
    property bool showHealth: true

    // When positive, off-scale contacts clamp to this pixel radius (the outer
    // ring) instead of plotting beyond it, so ranging in seats a contact that
    // no longer fits at the edge rather than losing it off the display.
    property real clampRadius: 0

    // How far past that radius a clamped symbol is seated, in half-symbol
    // extents: 1 stands the whole symbol clear of the radius, 0 puts the radius
    // through its centre, and more pushes it further out. Measured off each
    // symbol's own size, so a mark drawn small seats as close as a large one.
    property real clampMargin: 1

    // The live marks, keyed by contactId; sync() upserts and prunes.
    property var held: ({})

    transform: Rotation {
        origin.x: root.centerX
        origin.y: root.centerY
        angle: root.viewRotation
    }

    // One contact's mark. The track guards cover the window between the
    // sweep destroying a dropped track and the deferred teardown of its mark.
    component Mark: Loader {
        id: mark

        required property Track track

        readonly property real azimuth: mark.track ? mark.track.azimuth : 0
        readonly property real trueRange: mark.track ? mark.track.range * root.pxPerMeter : 0

        // Beyond the scale, and so clamped: the symbol steps out to its
        // seat past the clamp radius rather than plotting where it truly
        // is. A contact still on the scale is never pushed anywhere.
        readonly property bool offScale: root.clampRadius > 0 && mark.trueRange > root.clampRadius
        readonly property real screenRange: mark.offScale ? root.clampRadius + root.clampMargin * mark.height / 2 : mark.trueRange

        readonly property Component symbolMark: Component {
            Symbol {
                symbolSize: root.symbolSize
                strokeWidth: root.symbolStrokeWidth
                noseAngle: mark.track ? mark.track.heading : 0
                viewRotation: root.viewRotation
                classification: mark.track ? mark.track.classification : Classification.Kind.Unknown
                side: mark.track ? mark.track.side : Side.Kind.Unknown
                showLabel: root.showLabels
                label: !mark.track || mark.track.classification === Classification.Kind.Unknown ? "" : mark.track.contactId
                hasHealth: root.showHealth && mark.track && mark.track.maxHealth > 0
                healthFrac: mark.track ? mark.track.healthFrac : 1
            }
        }

        readonly property Component flareMark: Component {
            SymbolFlare {
                symbolSize: root.symbolSize
            }
        }

        x: root.centerX + Geo.offsetX(mark.azimuth, mark.screenRange) - width / 2
        y: root.centerY + Geo.offsetY(mark.azimuth, mark.screenRange) - height / 2

        // A contact classified as a countermeasure plots as a burning
        // flare, no faction symbol or label — briardart skips the symbol
        // the same way. Everything else keeps the classification mark.
        sourceComponent: mark.track && mark.track.classification === Classification.Kind.Decoy ? mark.flareMark : mark.symbolMark
    }

    readonly property Component markFactory: Component {
        Mark {}
    }

    onTracksChanged: root.sync()
    Component.onCompleted: root.sync()

    // Reconciles the marks with the roster: a new contact gets a mark, a
    // dropped one loses it, and every survivor keeps its live instance.
    function sync() {
        const present = new Set();
        for (let i = 0; i < root.tracks.length; ++i) {
            const track = root.tracks[i];
            present.add(track.contactId);
            if (root.held[track.contactId] === undefined) {
                root.held[track.contactId] = root.markFactory.createObject(root, {
                    track: track
                });
            }
        }
        for (const contactId in root.held) {
            if (!present.has(contactId)) {
                root.held[contactId].destroy();
                delete root.held[contactId];
            }
        }
    }
}
