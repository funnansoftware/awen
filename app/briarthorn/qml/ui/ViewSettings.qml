pragma ComponentBehavior: Bound

import QtQuick
import awen.gamepad
import "../input"
import "../model"
import "../themes"

// The controls page: one row per ability the flown craft carries, showing the
// key and the controller button that invoke it, rebound by picking a cap and
// pressing the control you want. Full-bleed and opaque, because the duel is
// stopped behind it, scrolling because a phone in landscape has room for about
// three rows, and driveable from a pad, so a controller player can reach every
// row without a keyboard.
//
// A sibling of the game scene rather than a child: a key it declines bubbles to
// the window instead of falling sideways into the scene's handler. Main owns
// opening and closing it, and focus follows open on both sides declaratively.
Item {
    id: root

    // The table being edited and the flown craft's live loadout: the rows are
    // exactly the abilities this airframe carries, so there are no dead ones.
    required property Keymap keymap
    required property list<AbilitySlot> loadout

    // Whether the page is up. Main drives this; focus and the pause follow it.
    property bool open: false

    // The ability waiting for a control and the device it waits on; the name is
    // empty when nothing is capturing.
    property string capturing: ""
    property bool capturingPad: false

    // The highlighted row, for keyboard and pad navigation, and whether RESET
    // ALL is armed — it discards every rebind, so it takes two presses.
    property int cursor: 0
    property bool resetArmed: false

    signal closed

    visible: root.open
    focus: root.open

    onOpenChanged: {
        root.capturing = "";
        root.cursor = 0;
        root.resetArmed = false;
        root.keymap.displaced = "";
    }

    // The ability at a row, or empty past the end or on a slot with no
    // definition.
    function abilityAt(index: int): string {
        if (index < 0 || index >= root.loadout.length)
            return "";
        const def = root.loadout[index].def;
        return def ? def.name : "";
    }

    function move(delta: int) {
        if (root.loadout.length > 0)
            root.cursor = (root.cursor + delta + root.loadout.length) % root.loadout.length;
    }

    function capture(name: string, pad: bool) {
        if (name === "")
            return;
        root.capturing = name;
        root.capturingPad = pad;
        root.resetArmed = false;
        root.keymap.displaced = "";
    }

    // The capture gate, in front of everything else: while a row is waiting, the
    // control the player presses becomes its binding and never does its usual
    // job. A control the keymap refuses is swallowed and the row keeps waiting,
    // so a mis-press onto a flight key binds nothing. Returns whether the event
    // was taken.
    function captured(pad: bool, code: int): bool {
        if (root.capturing === "")
            return false;
        if (pad ? code === Gamepad.Button.East : code === Qt.Key_Escape) {
            root.capturing = "";
            return true;
        }
        if (pad !== root.capturingPad)
            return true;
        if (root.keymap.bind(root.capturing, pad, code))
            root.capturing = "";
        return true;
    }

    // Two presses, because it throws away every rebind and there is no undo.
    function resetAll() {
        if (root.resetArmed)
            root.keymap.reset();
        root.resetArmed = !root.resetArmed;
    }

    function clearRow() {
        const name = root.abilityAt(root.cursor);
        root.keymap.unbind(name, false);
        root.keymap.unbind(name, true);
    }

    Keys.onPressed: event => {
        event.accepted = true;
        if (event.isAutoRepeat || root.captured(false, event.key))
            return;
        switch (event.key) {
        case Qt.Key_Up:
            root.move(-1);
            break;
        case Qt.Key_Down:
            root.move(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.capture(root.abilityAt(root.cursor), false);
            break;
        case Qt.Key_Delete:
        case Qt.Key_Backspace:
            root.clearRow();
            break;
        case Qt.Key_Escape:
        case Qt.Key_Back:
            root.closed();
            break;
        default:
            break;
        }
    }
    Keys.onReleased: event => event.accepted = true

    // The pad's whole vocabulary here. Controller events ignore focus entirely,
    // so Main hands them over explicitly while the page is up.
    function padPressed(code: int) {
        if (root.captured(true, code))
            return;
        switch (code) {
        case Gamepad.Button.DpadUp:
            root.move(-1);
            break;
        case Gamepad.Button.DpadDown:
            root.move(1);
            break;
        case Gamepad.Button.South:
            root.capture(root.abilityAt(root.cursor), true);
            break;
        case Gamepad.Button.West:
            root.clearRow();
            break;
        case Gamepad.Button.North:
            root.resetAll();
            break;
        case Gamepad.Button.East:
        case Gamepad.Button.Start:
            root.closed();
            break;
        default:
            break;
        }
    }

    // Opaque, and swallowing every pointer event: the on-screen stick sits
    // underneath, and a bare Item does not stop its handler grabbing a touch.
    Rectangle {
        anchors.fill: parent
        color: Style.theme.windowBackground

        MouseArea {
            anchors.fill: parent
        }
    }

    Text {
        id: heading

        text: qsTr("CONTROLS")
        color: Style.theme.textHeading
        anchors { left: parent.left; top: parent.top; margins: 28 }
        font { pixelSize: 18; bold: true; letterSpacing: 2 }
    }

    // Said plainly rather than pretended: in a browser refusing storage, or a
    // build with no application identity, rebinds last the session only.
    Text {
        visible: !root.keymap.available
        text: qsTr("this session only — controls cannot be saved here")
        color: Style.theme.warn
        font.pixelSize: 12
        anchors { left: heading.right; leftMargin: 16; baseline: heading.baseline }
    }

    Rectangle {
        id: rule

        height: 1
        color: Style.theme.frameInner
        anchors {
            left: parent.left
            right: parent.right
            top: heading.bottom
            leftMargin: 28
            rightMargin: 28
            topMargin: 10
        }
    }

    Flickable {
        clip: true
        contentHeight: rows.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        anchors {
            left: parent.left
            right: parent.right
            top: rule.bottom
            bottom: footer.top
            leftMargin: 28
            rightMargin: 28
            topMargin: 16
            bottomMargin: 16
        }

        Column {
            id: rows

            width: parent.width
            spacing: 4

            Repeater {
                model: root.loadout

                BindingRow {
                    required property AbilitySlot modelData
                    required property int index

                    width: rows.width
                    slot: modelData
                    selected: root.cursor === index
                    onPicked: root.cursor = index
                }
            }
        }
    }

    Column {
        id: footer

        spacing: 10
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 28
        }

        Row {
            spacing: 24

            Choice {
                text: root.resetArmed ? qsTr("PRESS AGAIN TO CONFIRM") : qsTr("RESET ALL")
                alarming: root.resetArmed
                onTapped: root.resetAll()
            }

            Choice {
                text: qsTr("DONE")
                onTapped: root.closed()
            }
        }

        Text {
            text: qsTr("↑↓ select · ENTER rebind · DEL clear · ESC back      pad: D-pad select · A rebind · X clear · Y defaults · B back")
            color: Style.theme.textMuted
            font.pixelSize: 12
        }
    }

    // One ability's row: its label and one cap per device, either of which is
    // the hit target for a rebind. The whole row selects on touch.
    component BindingRow: Rectangle {
        id: row

        required property AbilitySlot slot
        property bool selected: false
        readonly property string ability: row.slot.def ? row.slot.def.name : ""

        signal picked

        implicitHeight: 40
        radius: Style.theme.panelRadius
        color: row.selected ? Style.theme.panelBackground : "transparent"
        border.width: row.selected ? 1 : 0
        border.color: Style.theme.accent

        MouseArea {
            anchors.fill: parent
            onClicked: row.picked()
        }

        Text {
            text: row.slot.def ? row.slot.def.label : ""
            color: row.selected ? Style.theme.textBright : Style.theme.textPrimary
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
            font { pixelSize: 14; bold: true; letterSpacing: Style.theme.capsTracking }
        }

        Row {
            spacing: 6
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }

            Cap {
                ability: row.ability
                label: root.keymap.keyLabel(root.keymap.keyFor(row.ability))
                onPicked: row.picked()
            }

            Cap {
                ability: row.ability
                pad: true
                code: root.keymap.buttonFor(row.ability)
                label: root.keymap.buttonLabel(root.keymap.buttonFor(row.ability))
                onPicked: row.picked()
            }
        }
    }

    // One rebindable control: what is bound now, and a tap to capture the next
    // control pressed onto it. The device it belongs to is the cap's own pad
    // flag, which is what decides how it draws as well as what it captures.
    component Cap: ControlCap {
        id: cap

        required property string ability

        signal picked

        waiting: cap.ability !== "" && root.capturing === cap.ability && root.capturingPad === cap.pad
        displaced: cap.ability !== "" && root.keymap.displaced === cap.ability && root.keymap.displacedPad === cap.pad

        MouseArea {
            anchors.fill: parent
            onClicked: {
                cap.picked();
                root.capture(cap.ability, cap.pad);
            }
        }
    }

    // A plain text action in the footer.
    component Choice: Text {
        id: choice

        property bool alarming: false

        signal tapped

        color: choice.alarming ? Style.theme.warn : Style.theme.accent
        font { pixelSize: 13; bold: true; letterSpacing: Style.theme.capsTracking }

        MouseArea {
            anchors.fill: parent
            onClicked: choice.tapped()
        }
    }
}
