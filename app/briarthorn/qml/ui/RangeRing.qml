import QtQuick
import awen.shapes

ShapeRing {
    id: ring

    strokeColor: Style.theme.rangeRing

    property real padding: 10
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
        length: 8
        gapAngle: ring.gapAngle
        gapHalfAngle: ring.gapHalfAngle
        strokeColor: Style.theme.rangeRing
        strokeWidth: 1.5

        // One label per visible tick. tickAngles carries each tick's bearing;
        // the Repeater hands it to the delegate as modelData, and tickPoint
        // anchors the text just inside the tick's inner end.
        Repeater {
            model: ticks.tickAngles
            delegate: Text {
                required property real modelData
                text: Math.round(modelData) === 0 ? "N" : Math.round(modelData)
                color: Style.theme.textPrimary
                font.pixelSize: 10
                scale: Math.round(modelData) === 0 ? 1.5 : 1

                property point anchor: ticks.tickPoint(modelData, ticks.radius - ticks.length - ring.padding * 2)
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
