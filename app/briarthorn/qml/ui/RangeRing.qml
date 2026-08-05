pragma ComponentBehavior: Bound

import QtQuick
import awen.shapes
import "../themes"

ShapeRing {
    id: root

    // Tick geometry scales with the ring rather than sitting at static pixel
    // sizes, floored so a small scope stays legible.
    property real padding: Math.max(10, radius * 0.018)

    // The bearing labels' seat inset past the tick inner ends, budgeted off
    // the label text size (~0.9x its pixel size) so the widest label — and
    // the 1.5x-scaled 'N' — clears its tick at any radius.
    property real labelPadding: Math.max(16, radius * 0.03)
    property real range: 40
    property alias enableTicks: ticks.visible
    // Screen rotation of the tick assembly — bind -ownship.heading for a
    // heading-up scope whose labels keep true bearings.
    property alias tickOffset: ticks.angleOffset

    strokeColor: Style.theme.rangeRing

    ShapeTicks {
        id: ticks
        enabled: visible
        anchors.fill: parent
        centerX: root.centerX
        centerY: root.centerY
        stepAngle: 30
        radius: root.radius - root.padding
        length: Math.max(8, root.radius * 0.015)
        gapAngle: root.gapAngle
        gapHalfAngle: root.gapHalfAngle
        strokeColor: Style.theme.rangeRing
        strokeWidth: Math.max(1.5, root.radius * 0.0028)

        // One label per tick, anchored just inside the tick's inner end. The
        // model is the fixed tick count so delegates survive gap crossings;
        // a label rotating into the gap merely hides.
        Repeater {
            model: Math.ceil(360 / ticks.stepAngle)

            Text {
                required property int index
                readonly property real bearing: index * ticks.stepAngle
                property point anchor: ticks.tickPoint(bearing, ticks.radius - ticks.length - root.labelPadding)

                visible: !root.inGap(bearing + ticks.angleOffset)
                text: Math.round(bearing) === 0 ? "N" : Math.round(bearing)
                color: Style.theme.textPrimary
                font {
                    pixelSize: Math.max(15, root.radius * 0.03)
                    family: Style.monospace
                }
                scale: Math.round(bearing) === 0 ? 1.5 : 1

                x: anchor.x - width / 2
                y: anchor.y - height / 2
            }
        }
    }

    // The range label sits in the gap: centred on gapCenter and scaled about
    // its middle to span the gap's arc length.
    Text {
        color: Style.theme.textPrimary
        text: Math.round(parent.range)
        font {
            pixelSize: 12
            weight: Font.Bold
            family: Style.monospace
        }

        x: parent.gapCenter.x - width / 2
        y: parent.gapCenter.y - height / 2
        scale: parent.gapLength / (width + root.padding)
    }
}
