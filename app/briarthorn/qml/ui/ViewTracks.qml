pragma ComponentBehavior: Bound

import QtQuick
import awen.shapes
import "../database"
import "../model"
import "../themes"

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

    // Whether a resolved craft carries its range under its callsign. Every
    // range decision the game asks for — arm now or keep closing, run or turn
    // back in — is made against this number, and the scope is where it is
    // already being read off. Rides showLabels, since it hangs off the label.
    property bool showRanges: true

    // The pilot's designated contact and the contact a guided launch would
    // take right now, both by track id. Exactly one mark ever carries the
    // cursor — hunting-coloured while the selection cannot yet be taken,
    // latched where the two ids agree — so the scope answers "which one is
    // the shot going to" without a legend.
    property string selectedContact: ""
    property string shootableContact: ""

    // Whether a tap on a selectable mark designates it. Off by default, so
    // the minimap and the menu backdrop carry no handlers at all.
    property bool selectionEnabled: false

    // A tap on a selectable mark, by track id. The picture stays a display —
    // the caller posts the designation, this only reports the tap. A tap from
    // a touchscreen raises trackTouched with it, so the HUD can hand the
    // interface to the touch controls as the rack does.
    signal trackTapped(string contactId)
    signal trackTouched

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


    // One contact's mark: the classification symbol, plus the lock bracket on
    // the one contact carrying it. An Item rather than the bare Loader the
    // symbol loads into, because a Loader's default property is the component
    // it loads and a second child could not sit beside it. The track guards
    // cover the window between the sweep destroying a dropped track and the
    // deferred teardown of its mark.
    component Mark: Item {
        id: mark

        required property Track track

        readonly property real azimuth: mark.track ? mark.track.azimuth : 0
        readonly property real trueRange: mark.track ? mark.track.range * root.pxPerMeter : 0
        readonly property bool selected: root.selectedContact !== "" && mark.track !== null && mark.track.contactId === root.selectedContact
        readonly property bool latched: mark.selected && mark.track.contactId === root.shootableContact

        // Range under the callsign, on resolved craft only: maxHealth is the
        // one field the sweep leaves at zero for a contact it has not resolved
        // and that a munition or a decoy never carries, so it says "a craft,
        // and we know what it is" without a second test for either.
        readonly property string rangeCaption: root.showRanges && mark.track !== null && mark.track.maxHealth > 0 ? qsTr("%1 KM").arg((mark.track.range / 1000).toFixed(1)) : ""

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
                // Labels ride the view's switch and the kind's own say — a
                // tracer plots as a bare streak, not a captioned contact.
                showLabel: root.showLabels && (!mark.track || Database.dataFor(mark.track.classification).trackLabel)
                label: !mark.track || mark.track.classification === Classification.Kind.Unknown ? "" : mark.track.contactId
                caption: mark.rangeCaption
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
        // Sized by the symbol it carries, so the plot still seats the mark by
        // its own extent and the clamp still steps it out by half of one.
        width: symbol.width
        height: symbol.height

        Loader {
            id: symbol

            // A contact classified as a countermeasure plots as a burning
            // flare, no faction symbol or label — briardart skips the symbol
            // the same way. Everything else keeps the classification mark.
            sourceComponent: mark.track && mark.track.classification === Classification.Kind.Decoy ? mark.flareMark : mark.symbolMark
        }

        // The cursor: a screen-upright reticle counter-rotated the way the
        // symbol's own label is, loaded only on the selected mark — a
        // dogfight plots far more contacts than the pilot designates. Its
        // colour is the designation's whole state: hunting while the rack
        // cannot yet take the contact, latched the moment a launch would.
        Loader {
            anchors.centerIn: parent
            width: mark.width * 2.1
            height: width
            rotation: -root.viewRotation
            active: mark.selected
            sourceComponent: ShapeReticle {
                gap: width * 0.3
                armLength: width * 0.15
                strokeColor: mark.latched ? Style.theme.cursorLatched : Style.theme.cursorFree
                strokeWidth: Math.max(1.5, root.symbolStrokeWidth)
            }
        }

        // The mark's hit area, floored at a thumb target — the symbols draw
        // far smaller than a finger. A TapHandler rather than the rack's
        // PointHandler: its grab makes the topmost mark the only winner where
        // two overlap, and it takes touch and mouse without the synthetic
        // double-fire. The track guard covers the teardown window, as the
        // mark's own bindings do. The selected mark stays tappable even
        // unresolved — the designation survives losing the contact's picture,
        // so the tap that stands it down must survive with it.
        Loader {
            anchors.centerIn: parent
            width: Math.max(44, mark.width * 1.4)
            height: width
            active: root.selectionEnabled && mark.track !== null && (mark.track.selectable || mark.selected)
            sourceComponent: Item {
                TapHandler {
                    gesturePolicy: TapHandler.ReleaseWithinBounds
                    onTapped: eventPoint => {
                        if (mark.track === null)
                            return;
                        if (eventPoint.device.type === PointerDevice.TouchScreen)
                            root.trackTouched();
                        root.trackTapped(mark.track.contactId);
                    }
                }
            }
        }
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
