import QtQuick
import awen.shapes

ShapeRing {
    id: ring

    strokeColor: Style.theme.rangeRing

    property real rangeTextPadding: 10
    property real range: 40

    // The range label sits in the gap: centred on gapCenter and scaled about
    // its middle to span the gap's arc length.
    Text {
        color: Style.theme.textPrimary
        text: String(parent.range)
        font.weight: Font.Bold

        x: parent.gapCenter.x - width / 2
        y: parent.gapCenter.y - height / 2
        scale: parent.gapLength / (width + ring.rangeTextPadding)
    }
}
