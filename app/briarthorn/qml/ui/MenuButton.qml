import QtQuick
import "../themes"

// One themed menu action: lit by hover or the caller's cursor highlight,
// accent-bordered when primary, sliding in on an index stagger each time the
// owning overlay is revealed. Shared by the launch screen, the pause menu and
// the end screen, so every menu reads as one chrome.
Item {
    id: root

    // The stagger order — the row's position in its menu.
    required property int index

    property string label
    property bool primary: false

    // The cursor highlight, owned by the caller's Selector.
    property bool selected: false

    // Enlarges type and padding together; 1.0 is the compact card size.
    property real scaleFactor: 1

    // The owning overlay's visibility: each reveal replays the entrance.
    property bool revealed: true

    signal invoked

    readonly property bool active: mouse.containsMouse || root.selected

    // Breathing room above and below the caption, per side.
    readonly property real captionPadding: 13

    height: caption.implicitHeight + 2 * root.captionPadding * root.scaleFactor
    opacity: 0

    transform: Translate {
        id: slide
        x: -24
    }

    SequentialAnimation {
        running: root.revealed

        PropertyAction {
            target: root
            property: "opacity"
            value: 0
        }
        PropertyAction {
            target: slide
            property: "x"
            value: -24
        }
        PauseAnimation {
            duration: 150 + root.index * 90
        }
        ParallelAnimation {
            NumberAnimation {
                target: root
                property: "opacity"
                to: 1
                duration: 350
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: slide
                property: "x"
                to: 0
                duration: 350
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: root.active ? Qt.alpha(Style.theme.accent, 0.2) : Style.theme.instrumentBackground
        border.width: root.primary ? 2 : 1.5
        border.color: root.active ? Style.theme.accentBright : (root.primary ? Style.theme.accent : Style.theme.frameInner)

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }
    }

    Text {
        id: caption

        text: root.label
        color: root.primary ? Style.theme.textBright : Style.theme.textPrimary
        anchors.centerIn: parent
        font { pixelSize: 14 * root.scaleFactor; bold: true; letterSpacing: 2 * root.scaleFactor; family: Style.monospace }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.invoked()
    }
}
