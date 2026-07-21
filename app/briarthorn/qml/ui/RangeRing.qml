import awen.shapes

ShapeRing {
    anchors.fill: parent
    centerY: height * 0.875
    radius: Math.min(width, height) * 0.8
    strokeWidth: 2
    gapLength: parent.width * (1 / 24)
    gapAngle: 20
    strokeColor: root.style.theme.rangeRing
}
