import QtQuick
import "../themes"

// One bounded instrument frame of the tiled HUD: an opaque well, a hairline
// border and a small legend seated bottom-left, with the content clipped
// inside. The border is steady scope furniture by default; a tile whose
// whole state deserves a frame — the stores tile while a shot is armed —
// rebinds it.
Item {
    id: root

    // The legend and the frame.
    property string label: ""
    property color borderColor: Style.theme.rangeRing
    property real borderWidth: 1

    // The content parent an instance's children default into. The frame,
    // well and legend below are object properties with explicit parents
    // rather than plain children, because a default alias captures the
    // defining file's own children too — the well would be handed to itself.
    default property alias content: inner.data
    readonly property Item contentItem: Item {
        id: inner

        parent: root
        clip: true
        anchors.fill: parent
        anchors.margins: 8
    }

    readonly property Rectangle frame: Rectangle {
        parent: root
        z: -1
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.instrumentBackground
        border.width: root.borderWidth
        border.color: root.borderColor
    }

    // The legend, over the content so a busy tile never hides its name.
    // Placed by coordinates: an anchor line evaluated before the explicit
    // parent assignment lands warns about anchoring across the tree.
    readonly property Text legend: Text {
        parent: root
        z: 1
        x: 6
        y: root.height - height - 6
        text: root.label
        color: Style.theme.textLabel
        font { pixelSize: 10; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
    }
}
