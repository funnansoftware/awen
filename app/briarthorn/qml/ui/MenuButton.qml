import QtQuick
import "../audio"
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

    // Whether the entrance below has finished. Hover is only worth sounding
    // once the row has stopped moving: the buttons slide in from the left, and
    // a pointer left resting over the rail is entered and left by a button
    // arriving under it — cues the player never asked for, at the exact moment
    // the menu appears.
    property bool settled: false

    // Breathing room above and below the caption, per side.
    readonly property real captionPadding: 13

    height: caption.implicitHeight + 2 * root.captionPadding * root.scaleFactor
    opacity: 0

    // The highlight arriving — the pad and the keyboard's cursor, and theirs
    // alone. Hover sounds itself below.
    //
    // These were one hook on active (hover-or-highlight) and that was the bug:
    // active is an OR, so a button the pointer happens to be resting on is
    // already active, and the highlight landing on it changes nothing and so
    // says nothing. Every menu has a row under the mouse, which is the tick
    // that goes missing part-way down a menu — and why it comes and goes with
    // where the mouse was left.
    //
    // Guarded on visibility because the launch screen instantiates both its
    // layouts and hides one: every button exists twice there, and an unguarded
    // cue would sound the hidden copy's arrival alongside the shown one's.
    onSelectedChanged: if (root.selected && root.visible)
        Sfx.navigate()

    transform: Translate {
        id: slide
        x: -24
    }

    SequentialAnimation {
        running: root.revealed

        PropertyAction {
            target: root
            property: "settled"
            value: false
        }
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
        PropertyAction {
            target: root
            property: "settled"
            value: true
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
        // The pointer's own arrival, on the event rather than on a recomputed
        // state: entering is something the player did, where active becoming
        // true is merely something that became true.
        onEntered: if (root.settled)
            Sfx.navigate()
        // Sounded before the action, which runs synchronously and may take the
        // whole screen down with it.
        onClicked: {
            Sfx.press();
            root.invoked();
        }
    }
}
