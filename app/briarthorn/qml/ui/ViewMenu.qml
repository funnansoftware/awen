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
    signal settingsRequested
    signal exitGame

    // Which device the player is driving with; the menu's keys report in, as
    // the settings page's do.
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
                label: qsTr("SETTINGS"),
                primary: false,
                act: () => root.settingsRequested()
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
    // here bubbles on to the window.
    //
    // A key the menu acts on is accepted, and accepted explicitly: a QML key
    // event arrives at its handler unaccepted, so a branch that only acts is a
    // branch that also leaks. An entry acts synchronously — DUEL has already
    // started the duel and cleared the menu by the time this handler returns —
    // so a leaked press lands on the game the menu just started, and the space
    // bar that picked DUEL fires an ability into the opening frame.
    Keys.onPressed: event => {
        event.accepted = true;
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
    // menu is up, as it does for the settings page.
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
        color: Qt.alpha(Style.theme.windowBackground, 0.8)
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
                required property var modelData

                width: root.buttonWidth
                scaleFactor: root.uiScale
                label: modelData.label
                primary: modelData.primary
                selected: root.cursor.engaged && root.cursor.index === index
                revealed: root.visible
                onInvoked: modelData.act()
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
                    required property var modelData

                    width: cardColumn.width
                    label: modelData.label
                    primary: modelData.primary
                    selected: root.cursor.engaged && root.cursor.index === index
                    revealed: root.visible
                    onInvoked: modelData.act()
                }
            }
        }
    }
}
