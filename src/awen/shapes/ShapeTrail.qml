pragma ComponentBehavior: Bound

import QtQuick

// A motion wake: the fading breadcrumb dots of an object's recent positions,
// drawn as offsets from its current position about the anchor point, newest
// dot largest and brightest. record() maintains the history ring; positions
// are in source units, scaled to pixels by positionScale, and a parent frame
// rotation carries any heading-up turn, so the dots need none of their own.
// Each dot sits fixed at its sample point inside one sliding frame — the only
// per-frame work is that frame's translation, however long the tail. Not on
// QtQuick.Shapes like its siblings: each dot fades to its own alpha, which
// one ShapePath's single fill cannot express.
Item {
    id: root

    // Recent positions, oldest first, in source units; record() maintains it.
    property list<point> points

    // Samples kept; record() drops the oldest past this.
    property int capacity: 20

    // The tracked object's current position, in the same units as points —
    // each dot plots at its sample's offset from here, scaled.
    property real currentX: 0
    property real currentY: 0

    // Source units to pixels.
    property real positionScale: 1

    // The anchor the offsets plot about.
    property real centerX: width / 2
    property real centerY: height / 2

    // The newest dot's diameter (px) and opacity; both fade down the tail.
    property real dotSize: 4
    property real maxOpacity: 0.9
    property color color: "white"

    // The sliding frame: dots hold their scaled sample coordinates and the
    // whole wake rides the object's live position through this one offset.
    Item {
        x: root.centerX - root.currentX * root.positionScale
        y: root.centerY - root.currentY * root.positionScale

        Repeater {
            model: root.points.length

            Rectangle {
                id: dot

                required property int index

                // The guard covers the re-evaluation window while the roster
                // settles after a sample lands or the history is dropped.
                readonly property point sample: dot.index < root.points.length ? root.points[dot.index] : Qt.point(root.currentX, root.currentY)

                // Freshness: ~0 at the tail, 1 at the newest sample.
                readonly property real freshness: root.points.length > 0 ? (dot.index + 1) / root.points.length : 0

                x: dot.sample.x * root.positionScale - width / 2
                y: dot.sample.y * root.positionScale - height / 2
                width: root.dotSize * (0.35 + 0.65 * dot.freshness)
                height: width
                radius: width / 2
                color: root.color
                opacity: root.maxOpacity * dot.freshness
            }
        }
    }

    // The plotted centre of one dot in item pixels — computed on call, so
    // reading it costs nothing per frame.
    function dotCenter(index: int): point {
        return Qt.point(centerX + (points[index].x - currentX) * positionScale, centerY + (points[index].y - currentY) * positionScale);
    }

    // Appends one position sample, dropping the oldest past capacity.
    function record(x: real, y: real) {
        const overflow = root.points.length - root.capacity + 1;
        const kept = overflow > 0 ? root.points.slice(overflow) : root.points.slice();
        kept.push(Qt.point(x, y));
        root.points = kept;
    }

    // Drops the recorded history — for an object being reused or repositioned.
    function reset() {
        root.points = [];
    }
}
