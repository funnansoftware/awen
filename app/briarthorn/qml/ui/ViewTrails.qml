pragma ComponentBehavior: Bound

import QtQuick
import awen.shapes
import "../database"
import "../model"
import "../themes"

// The motion-wake layer: per object, the fading dots of its recent world
// track — ownship's about the scope centre, each contact's about its plotted
// mark — sampled on a fixed clock and drawn at a constant exaggerated scale,
// so a wake reads identically at every range step (length = speed, curvature
// = turn history). Wakes are keyed per contact and pruned with the track, so
// roster churn never resets a live tail. Ports briardart's trail pass.
Item {
    id: root

    // The observer whose picture this decorates and the contacts trailed.
    property Entity observer
    property list<Track> tracks

    // Scope centre in item coordinates and the world-to-screen scale.
    property real centerX: width / 2
    property real centerY: height / 2
    property real pxPerMeter: 0

    // Screen rotation of the picture about the scope centre.
    property real viewRotation: 0

    // World metres to wake pixels — deliberately not the projection's scale.
    property real trailScale: 0.08

    // The sampling clock: one sample per interval (ms), capacity samples kept
    // (~4 s of wake). running false freezes the wakes with the sim.
    property int interval: 200
    property int capacity: 20
    property bool running: true

    // Off-scale contacts clamp their anchors to this pixel radius (the outer
    // ring), like the symbols they trail; 0 leaves them unclamped.
    property real clampRadius: 0

    // The live wakes, keyed by contactId; sample() upserts and prunes.
    property var held: ({})

    // The observer's position last pass, for the teleport guard: no craft
    // moves this far in one interval, so a bigger step is a scene reset (the
    // menu demo reopening, a new game) and the history must not smear across
    // it. Primed on the first pass after a clear.
    readonly property real teleportRange: 5000
    property real lastX: 0
    property real lastY: 0
    property bool primed: false

    transform: Rotation {
        origin.x: root.centerX
        origin.y: root.centerY
        angle: root.viewRotation
    }

    // A contact's wake, anchored at its plotted (possibly clamped) mark and
    // hung off its live world position, so the tail tracks between samples.
    // The track guards cover the window between its destruction on the sweep
    // and this layer's next sampling pass pruning the wake.
    component Wake: ShapeTrail {
        id: wake

        required property Track track

        readonly property real azimuth: wake.track ? wake.track.azimuth : 0
        readonly property real trueRange: wake.track ? wake.track.range * root.pxPerMeter : 0
        readonly property real screenRange: root.clampRadius > 0 ? Math.min(wake.trueRange, root.clampRadius) : wake.trueRange

        anchors.fill: parent
        capacity: root.capacity
        positionScale: root.trailScale
        currentX: root.observer && wake.track ? root.observer.posX + Geo.offsetX(wake.azimuth, wake.track.range) : 0
        currentY: root.observer && wake.track ? root.observer.posY + Geo.offsetY(wake.azimuth, wake.track.range) : 0
        centerX: root.centerX + Geo.offsetX(wake.azimuth, wake.screenRange)
        centerY: root.centerY + Geo.offsetY(wake.azimuth, wake.screenRange)
        color: {
            switch (wake.track ? wake.track.side : Side.Kind.Unknown) {
            case Side.Kind.Ownship:
                return Style.theme.factionOwnship;
            case Side.Kind.Friendly:
                return Style.theme.factionFriendly;
            case Side.Kind.Neutral:
                return Style.theme.factionNeutral;
            case Side.Kind.Hostile:
                return Style.theme.factionHostile;
            default:
                return Style.theme.factionUnknown;
            }
        }
    }

    readonly property Component wakeFactory: Component {
        Wake {}
    }

    // Ownship's wake, anchored at the scope centre.
    ShapeTrail {
        id: ownshipWake

        anchors.fill: parent
        capacity: root.capacity
        positionScale: root.trailScale
        currentX: root.observer ? root.observer.posX : 0
        currentY: root.observer ? root.observer.posY : 0
        centerX: root.centerX
        centerY: root.centerY
        color: Style.theme.factionOwnship
    }

    Timer {
        interval: root.interval
        repeat: true
        running: root.running
        onTriggered: root.sample()
    }

    // Stale wakes from a previous showing would smear across a reset world,
    // so a layer being brought back starts clean.
    onVisibleChanged: root.clear()

    // One sampling pass: every live object records its current world position
    // into its wake, and wakes whose track has gone are pruned with it.
    // Munitions and unresolved contacts carry no wake — a sky full of rounds
    // and maybe-rounds each towing a tail buries the craft picture the trails
    // exist to read — so only a contact identified as a craft trails, and one
    // losing that identification sheds its wake in the same pass.
    function sample() {
        if (!root.observer)
            return;
        if (root.primed && Geo.distanceFrom(root.lastX, root.lastY, root.observer.posX, root.observer.posY) > root.teleportRange)
            root.clear();
        root.lastX = root.observer.posX;
        root.lastY = root.observer.posY;
        root.primed = true;
        ownshipWake.record(root.observer.posX, root.observer.posY);
        const present = new Set();
        for (let i = 0; i < root.tracks.length; ++i) {
            const track = root.tracks[i];
            if (track.classification === Classification.Kind.Unknown || Database.weaponDataFor(track.classification) !== null)
                continue;
            present.add(track.contactId);
            let wake = root.held[track.contactId];
            if (wake === undefined) {
                wake = root.wakeFactory.createObject(root, {
                    track: track
                });
                root.held[track.contactId] = wake;
            }
            wake.record(wake.currentX, wake.currentY);
        }
        for (const contactId in root.held) {
            if (!present.has(contactId)) {
                root.held[contactId].destroy();
                delete root.held[contactId];
            }
        }
    }

    // Drops every wake — the whole picture, not one contact's history.
    function clear() {
        ownshipWake.reset();
        for (const contactId in root.held)
            root.held[contactId].destroy();
        root.held = {};
        root.primed = false;
    }
}
