pragma ComponentBehavior: Bound

import QtQuick
import awen.gamepad
import awen.input
import "../input"
import "../themes"

// A scrim-and-card overlay menu: a dimmed backdrop over the frozen scene, a
// centred themed card with a title, an optional subtitle and one MenuButton
// per entry, driven by mouse, keys (on the page's focus) and the pad routed
// through Main — the pause and end screens are thin configurations of this.
// The launch screen keeps its own bespoke layout.
Item {
    id: root

    // Which device the player is driving with; the page's keys report in.
    required property ActiveDevice device

    property string title
    property color titleColor: Style.theme.textBright
    property string subtitle: ""

    // The ordered actions: {label, primary, act} records, as ViewMenu builds.
    property var entries: []

    // Whether Escape / pad East backs out of the page; the end screen has
    // nowhere to back out to, so it declines them.
    property bool dismissible: false

    signal dismissed

    // The pad/keyboard cursor over the entries; mouse hover stays independent.
    readonly property Selector cursor: Selector {
        count: root.entries.length
        onActivated: index => root.entries[index].act()
    }

    // A page being (re)shown starts unnavigated.
    onVisibleChanged: if (visible)
        root.cursor.reset()

    // The left stick steps the cursor once per push, re-armed at centre.
    Axis {
        id: navAxis
        onStepped: direction => root.cursor.move(direction)
    }

    // A key this page acts on is accepted, and accepted explicitly: a QML key
    // event arrives at its handler unaccepted, so a branch that only acts is a
    // branch that also leaks. The entries act synchronously — RESUME has
    // already unpaused, FLY AGAIN already started the next duel — so a leaked
    // press lands on the running game the page just handed back to, and the
    // space bar that picked the entry fires an ability with it.
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
        case Qt.Key_Escape:
        case Qt.Key_Back:
            if (root.dismissible)
                root.dismissed();
            else
                event.accepted = false;
            break;
        default:
            event.accepted = false;
            break;
        }
    }

    // The pad's vocabulary; Main hands buttons over while the page is up.
    // Start doubles as the way back where there is one — it opened the pause
    // menu, so it closes it too.
    function padPressed(button: int) {
        switch (button) {
        case Gamepad.Button.DpadUp:
            root.cursor.move(-1);
            break;
        case Gamepad.Button.DpadDown:
            root.cursor.move(1);
            break;
        case Gamepad.Button.South:
            root.cursor.activate();
            break;
        case Gamepad.Button.East:
        case Gamepad.Button.Start:
            if (root.dismissible)
                root.dismissed();
            else if (button === Gamepad.Button.Start)
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

    // The scrim: dims the frozen scene and swallows every pointer event.
    Rectangle {
        anchors.fill: parent
        color: "#CC05080D"

        MouseArea {
            anchors.fill: parent
        }
    }

    Rectangle {
        id: card

        width: Math.min(380, root.width - 32)
        height: column.implicitHeight + 52
        color: Style.theme.panelBackground
        border.color: Style.theme.frameInner
        border.width: 1
        radius: Style.theme.panelRadius
        anchors.centerIn: parent

        Column {
            id: column

            spacing: 6

            anchors {
                left: parent.left
                right: parent.right
                verticalCenter: parent.verticalCenter
                leftMargin: 28
                rightMargin: 28
            }

            Text {
                text: root.title
                color: root.titleColor
                anchors.horizontalCenter: parent.horizontalCenter
                font { pixelSize: 28; bold: true; letterSpacing: 4; family: Style.monospace }
            }

            Text {
                visible: root.subtitle !== ""
                text: root.subtitle
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

                    width: column.width
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
