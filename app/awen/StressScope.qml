import QtQuick
import awen.shapes

// A synthetic scope stress page: one rotated world layer, pooled contact
// symbols with dot trails, sweeping sector wedges and re-tessellating
// detonation arcs, with live frame stats — the briarthorn scope architecture
// under load before the port commits to it.
Rectangle {
    id: root
    color: "#101418"

    readonly property int contactCount: 30
    readonly property int trailCount: 20

    // The simulated clock in seconds; every animation below binds to it.
    property real t: 0

    // Ownship heading sweeps continuously to exercise the world rotation.
    readonly property real heading: t * 20 % 360

    // Frame statistics over a rolling window.
    property real frameAvgMs: 0
    property real frameP95Ms: 0
    property var samples: []

    FrameAnimation {
        running: root.visible
        onTriggered: {
            root.t += frameTime;
            const s = root.samples;
            s.push(frameTime * 1000);
            if (s.length >= 120) {
                const sorted = s.slice().sort((a, b) => a - b);
                let sum = 0;
                for (let i = 0; i < sorted.length; ++i)
                    sum += sorted[i];
                root.frameAvgMs = sum / sorted.length;
                root.frameP95Ms = sorted[Math.floor(sorted.length * 0.95)];
                root.samples = [];
            }
        }
    }

    // Screen-fixed range rings; the outer one carries the label and the gap
    // window the tick labels test against.
    ShapeRing {
        id: outerRing
        anchors.fill: parent
        radius: Math.min(width, height) * 0.4
        gapAngle: 25
        gapLength: 50
        strokeColor: "#8899aa"
        strokeWidth: 2.5

        Text {
            x: outerRing.gapCenter.x - width / 2
            y: outerRing.gapCenter.y - height / 2
            text: "40"
            color: "white"
            font.bold: true
            font.pixelSize: 13
        }
    }

    ShapeRing {
        anchors.fill: parent
        radius: Math.min(width, height) * 0.2
        gapAngle: 25
        gapLength: 50
        strokeColor: "#668899aa"
        strokeWidth: 2
    }

    // Heading-up bearing ticks; the marks re-tessellate as one PathSvg while
    // the labels ride tickPoint and hide inside the ring gap without churn.
    ShapeTicks {
        id: ticks
        anchors.fill: parent
        radius: outerRing.radius + 8
        length: 10
        angleOffset: -root.heading
        gapAngle: outerRing.gapAngle
        gapHalfAngle: outerRing.gapHalfAngle
        strokeColor: "#8899aa"
    }

    Repeater {
        model: 12
        Text {
            id: tickLabel
            required property int index
            readonly property real bearing: index * 30
            readonly property point p: ticks.tickPoint(bearing, ticks.radius + 18)
            x: p.x - width / 2
            y: p.y - height / 2
            visible: !outerRing.inGap(bearing + ticks.angleOffset)
            text: bearing === 0 ? "N" : bearing
            color: "#aabbcc"
            font.pixelSize: 11
        }
    }

    // The rotated world: one matrix update per frame carries everything below.
    Item {
        id: world
        anchors.fill: parent
        rotation: -root.heading

        // Sweeping SAM wedges: fixed sector geometry, only Item rotation
        // animates — no re-tessellation.
        Repeater {
            model: 3
            Item {
                id: site
                required property int index
                x: world.width / 2 + Math.sin(index * 2.1) * 200 - width / 2
                y: world.height / 2 - Math.cos(index * 2.1) * 200 - height / 2
                width: 160
                height: 160

                ShapeArc {
                    anchors.fill: parent
                    strokeColor: "#55ff6644"
                    strokeWidth: 1
                }

                ShapeSector {
                    anchors.fill: parent
                    angleSpan: 40
                    fillColor: "#22ff6644"
                    rotation: root.t * 115 + site.index * 120
                }
            }
        }

        // Pooled contacts, each a transform-driven symbol trailing a fading
        // dot wake computed per frame.
        Repeater {
            model: root.contactCount
            Item {
                id: contact
                required property int index
                readonly property real phase: root.t * (0.2 + index % 5 * 0.06) + index * 1.7
                readonly property real orbitR: 60 + index * 9
                x: world.width / 2 + Math.sin(phase) * orbitR
                y: world.height / 2 - Math.cos(phase) * orbitR

                Repeater {
                    model: root.trailCount
                    Rectangle {
                        required property int index
                        readonly property real back: (index + 1) * 0.06
                        width: 3
                        height: 3
                        radius: 1.5
                        x: (Math.sin(contact.phase - back) - Math.sin(contact.phase)) * contact.orbitR
                        y: (Math.cos(contact.phase) - Math.cos(contact.phase - back)) * contact.orbitR
                        color: Qt.rgba(1, 0.63, 0, 0.9 * (1 - index / root.trailCount))
                    }
                }

                ShapePolygon {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    points: [Qt.point(0, -0.5), Qt.point(0.42, 0.42), Qt.point(0, 0.12), Qt.point(-0.42, 0.42)]
                    fillColor: "#38ffa100"
                    strokeColor: "#ffa100"
                    rotation: contact.phase * 180 / Math.PI + 90
                }

                // The selected contact's health arc: counter-rotated so it
                // stays screen-stable, its sweep re-tessellating as it drains.
                ShapeGauge {
                    anchors.centerIn: parent
                    width: 30
                    height: 30
                    visible: contact.index === 0
                    rotation: root.heading
                    angleStart: 198
                    angleSweep: 144
                    radius: 13
                    strokeWidth: 2
                    value: 0.5 + 0.5 * Math.sin(root.t)
                    trackColor: "#3300ff88"
                    fillColor: "#00ff88"
                }
            }
        }

        // Expanding detonation rings — deliberate per-frame path changes.
        Repeater {
            model: 2
            ShapeArc {
                required property int index
                readonly property real cycle: (root.t * 0.7 + index * 0.5) % 1
                anchors.centerIn: parent
                width: 300
                height: 300
                radius: 10 + cycle * 130
                strokeColor: Qt.rgba(1, 0.85, 0.4, 1 - cycle)
                strokeWidth: 2
            }
        }
    }

    ShapeReticle {
        anchors.centerIn: parent
        width: 40
        height: 40
        strokeColor: "#ffd24d"
    }

    Text {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 16
        color: "white"
        font.pixelSize: 13
        text: "frame avg " + root.frameAvgMs.toFixed(2) + " ms   p95 " + root.frameP95Ms.toFixed(2) + " ms   (S closes)"
    }
}
