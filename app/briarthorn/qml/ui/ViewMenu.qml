pragma ComponentBehavior: Bound

import QtQuick
import awen.gamepad
import awen.input
import "../input"
import "../themes"

// The launch screen, laid transparent over the live demo scope so the real
// tactical picture shows through. On a wide window the title sits top-centre
// and the actions on a left rail, clear of the shifted picture; a narrow
// window falls back to a dimmed centred card. The buttons take the mouse and
// the pad/keyboard cursor alike. Ports briardart's MainMenuOverlay.
Item {
    id: root

    // Fired by the menu's actions; Main owns what they do.
    signal duel
    signal controls
    signal exitGame

    // Which device the player is driving with; the menu's keys report in, as
    // the controls page's do.
    required property ActiveDevice device

    // The pad/keyboard cursor over the actions. Mouse hover is independent,
    // so the highlight only appears once the player actually navigates.
    readonly property Selector cursor: Selector {
        count: root.entries.length
        onActivated: index => root.entries[index].act()
    }

    // The menu's actions in order, shared by both layouts and the cursor.
    // The web build has no window of its own to close, so it carries no exit.
    readonly property var entries: {
        const list = [
            {
                label: qsTr("DUEL"),
                primary: true,
                act: () => root.duel()
            },
            {
                label: qsTr("CONTROLS"),
                primary: false,
                act: () => root.controls()
            }
        ];
        if (Qt.platform.os !== "wasm") {
            list.push({
                label: qsTr("EXIT GAME"),
                primary: false,
                act: () => root.exitGame()
            });
        }
        return list;
    }

    // Below this width the left rail would crowd the scope picture, so the
    // layout falls back to the dimmed centred card.
    readonly property bool wide: width >= 820

    // Grow the rail buttons with the window so a maximised big display does
    // not leave them tiny: 1.0 at the breakpoint, up to 1.6.
    readonly property real uiScale: Math.max(1, Math.min(1.6, width / 1600))
    readonly property real buttonWidth: 300 * uiScale

    // A menu being (re)shown starts unnavigated, like a console front-end.
    onVisibleChanged: if (visible)
        root.cursor.reset()

    // The left stick steps the cursor once per push: the axis's rest band
    // re-arms on return to centre, so a held stick never scrolls away.
    Axis {
        id: navAxis
        onStepped: direction => root.cursor.move(direction)
    }

    // The keyboard vocabulary, on the menu's own focus — the Qt way round:
    // Main gives the launch screen focus while it is up, and a key declined
    // here bubbles on to the scene, which ignores it in menu mode.
    Keys.onPressed: event => {
        if (event.isAutoRepeat) {
            event.accepted = false;
            return;
        }
        root.device.kind = ActiveDevice.Keyboard;
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_W:
            root.cursor.move(-1);
            break;
        case Qt.Key_Down:
        case Qt.Key_S:
            root.cursor.move(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            root.cursor.activate();
            break;
        default:
            event.accepted = false;
            break;
        }
    }

    // The pad's whole vocabulary here; Main hands buttons over while the
    // menu is up, as it does for the controls page.
    function padPressed(button: int) {
        switch (button) {
        case Gamepad.Button.DpadUp:
            root.cursor.move(-1);
            break;
        case Gamepad.Button.DpadDown:
            root.cursor.move(1);
            break;
        case Gamepad.Button.South:
        case Gamepad.Button.Start:
            root.cursor.activate();
            break;
        default:
            break;
        }
    }

    function axisMoved(axis: int, value: real) {
        if (axis === Gamepad.Axis.LeftY)
            navAxis.invoke(value);
    }

    // Swallows pointer events across the whole screen, so a click on the
    // scope area can't reach the game controls underneath.
    MouseArea {
        anchors.fill: parent
    }

    // The narrow fallback's scrim: lifts the card's contrast over the live
    // picture and dims the demo it covers.
    Rectangle {
        anchors.fill: parent
        visible: !root.wide
        color: "#CC05080D"
    }

    // Title block, top-centre in the clear band above the wide picture.
    Column {
        id: masthead

        visible: root.wide
        spacing: 8
        opacity: 0

        anchors {
            top: parent.top
            topMargin: 52
            horizontalCenter: parent.horizontalCenter
        }

        transform: Translate {
            id: mastheadDrop
            y: -16
        }

        SequentialAnimation {
            running: root.visible

            PropertyAction {
                target: masthead
                property: "opacity"
                value: 0
            }
            PropertyAction {
                target: mastheadDrop
                property: "y"
                value: -16
            }
            ParallelAnimation {
                NumberAnimation {
                    target: masthead
                    property: "opacity"
                    to: 1
                    duration: 600
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: mastheadDrop
                    property: "y"
                    to: 0
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            text: qsTr("BRIARTHORN")
            color: Style.theme.textBright
            anchors.horizontalCenter: parent.horizontalCenter
            font { pixelSize: 44; bold: true; letterSpacing: 8; family: Style.monospace }
        }

        Text {
            text: qsTr("TACTICAL DEMO")
            color: Style.theme.textLabel
            anchors.horizontalCenter: parent.horizontalCenter
            font { pixelSize: 13; letterSpacing: 5; family: Style.monospace }
        }

        Rectangle {
            width: 210
            height: 1.5
            color: Style.theme.frameInner
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // The action rail, seated in the left clear zone about a quarter in from
    // the edge and vertically centred over the picture.
    Column {
        visible: root.wide
        x: Math.max(48, root.width * 0.25 - root.buttonWidth / 2)
        spacing: 12 * root.uiScale
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
            model: root.entries

            MenuButton {
                width: root.buttonWidth
                scaleFactor: root.uiScale
            }
        }
    }

    // The compact fallback: the title and the same actions on a centred card.
    Rectangle {
        id: card

        visible: !root.wide
        width: Math.min(380, root.width - 32)
        height: cardColumn.implicitHeight + 52
        color: Style.theme.panelBackground
        border.color: Style.theme.frameInner
        border.width: 1
        radius: Style.theme.panelRadius
        anchors.centerIn: parent

        Column {
            id: cardColumn

            spacing: 6

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 28
                rightMargin: 28
            }

            Text {
                text: qsTr("BRIARTHORN")
                color: Style.theme.textBright
                anchors.horizontalCenter: parent.horizontalCenter
                font { pixelSize: 28; bold: true; letterSpacing: 4; family: Style.monospace }
            }

            Text {
                text: qsTr("TACTICAL DEMO")
                color: Style.theme.textLabel
                anchors.horizontalCenter: parent.horizontalCenter
                font { pixelSize: 12; letterSpacing: 3; family: Style.monospace }
            }

            Item {
                width: 1
                height: 14
            }

            Repeater {
                model: root.entries

                MenuButton {
                    width: cardColumn.width
                }
            }
        }
    }

    // One themed action: lit by hover or the engaged cursor, accent-bordered
    // when primary, sliding in on a stagger as the menu shows.
    component MenuButton: Item {
        id: button

        required property var modelData
        required property int index
        property real scaleFactor: 1

        readonly property bool active: mouse.containsMouse || (root.cursor.engaged && root.cursor.index === button.index)

        // Breathing room above and below the caption, per side.
        readonly property real captionPadding: 13

        height: caption.implicitHeight + 2 * button.captionPadding * button.scaleFactor
        opacity: 0

        transform: Translate {
            id: slide
            x: -24
        }

        SequentialAnimation {
            running: root.visible

            PropertyAction {
                target: button
                property: "opacity"
                value: 0
            }
            PropertyAction {
                target: slide
                property: "x"
                value: -24
            }
            PauseAnimation {
                duration: 150 + button.index * 90
            }
            ParallelAnimation {
                NumberAnimation {
                    target: button
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
            color: button.active ? Qt.alpha(Style.theme.accent, 0.2) : Style.theme.instrumentBackground
            border.width: button.modelData.primary ? 2 : 1.5
            border.color: button.active ? Style.theme.accentBright : (button.modelData.primary ? Style.theme.accent : Style.theme.frameInner)

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

            text: button.modelData.label
            color: button.modelData.primary ? Style.theme.textBright : Style.theme.textPrimary
            anchors.centerIn: parent
            font { pixelSize: 14 * button.scaleFactor; bold: true; letterSpacing: 2 * button.scaleFactor; family: Style.monospace }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.modelData.act()
        }
    }
}
