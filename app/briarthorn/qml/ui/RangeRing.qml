import QtQuick
import awen.shapes

ShapeRing {
    id: ring

    strokeColor: Style.theme.rangeRing

    // Tick geometry scales with the ring, so bearing labels stay legible on a
    // large window instead of shrinking to a static 10px. Floored at the design
    // sizes, so a default-size scope looks unchanged.
    property real padding: Math.max(10, radius * 0.018)
    property real range: 40
    property alias enableTicks: ticks.visible
    // Screen rotation of the tick assembly — bind -ownship.heading for a
    // heading-up scope whose labels keep true bearings.
    property alias tickOffset: ticks.angleOffset

    ShapeTicks {
        id: ticks
        enabled: visible
        anchors.fill: parent
        centerX: ring.centerX
        centerY: ring.centerY
        stepAngle: 30
        radius: ring.radius - ring.padding
        length: Math.max(8, ring.radius * 0.015)
        gapAngle: ring.gapAngle
        gapHalfAngle: ring.gapHalfAngle
        strokeColor: Style.theme.rangeRing
        strokeWidth: Math.max(1.5, ring.radius * 0.0028)

        // One label per tick, anchored just inside the tick's inner end. The
        // model is the fixed tick count so delegates survive gap crossings;
        // a label rotating into the gap merely hides.
        Repeater {
            model: Math.ceil(360 / ticks.stepAngle)
            delegate: Text {
                required property int index
                readonly property real bearing: index * ticks.stepAngle
                visible: !ring.inGap(bearing + ticks.angleOffset)
                text: Math.round(bearing) === 0 ? "N" : Math.round(bearing)
                color: Style.theme.textPrimary
                font.pixelSize: Math.max(10, ring.radius * 0.02)
                scale: Math.round(bearing) === 0 ? 1.5 : 1

                property point anchor: ticks.tickPoint(bearing, ticks.radius - ticks.length - ring.padding)
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
        font.weight: Font.Bold

        x: parent.gapCenter.x - width / 2
        y: parent.gapCenter.y - height / 2
        scale: parent.gapLength / (width + ring.padding)
    }
}
