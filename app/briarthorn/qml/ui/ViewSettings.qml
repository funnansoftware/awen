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
    id: page

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

    visible: page.open
    focus: page.open

    onOpenChanged: {
        page.capturing = "";
        page.cursor = 0;
        page.resetArmed = false;
        page.keymap.displaced = "";
    }

    // The ability at a row, or empty past the end or on a slot with no
    // definition.
    function abilityAt(index: int): string {
        if (index < 0 || index >= page.loadout.length)
            return "";
        const def = page.loadout[index].def;
        return def ? def.name : "";
    }

    function move(delta: int) {
        if (page.loadout.length > 0)
            page.cursor = (page.cursor + delta + page.loadout.length) % page.loadout.length;
    }

    function capture(name: string, pad: bool) {
        if (name === "")
            return;
        page.capturing = name;
        page.capturingPad = pad;
        page.resetArmed = false;
        page.keymap.displaced = "";
    }

    // The capture gate, in front of everything else: while a row is waiting, the
    // control the player presses becomes its binding and never does its usual
    // job. A control the keymap refuses is swallowed and the row keeps waiting,
    // so a mis-press onto a flight key binds nothing. Returns whether the event
    // was taken.
    function captured(pad: bool, code: int): bool {
        if (page.capturing === "")
            return false;
        if (pad ? code === Gamepad.Button.East : code === Qt.Key_Escape) {
            page.capturing = "";
            return true;
        }
        if (pad !== page.capturingPad)
            return true;
        if (page.keymap.bind(page.capturing, pad, code))
            page.capturing = "";
        return true;
    }

    // Two presses, because it throws away every rebind and there is no undo.
    function resetAll() {
        if (page.resetArmed)
            page.keymap.reset();
        page.resetArmed = !page.resetArmed;
    }

    function clearRow() {
        const name = page.abilityAt(page.cursor);
        page.keymap.unbind(name, false);
        page.keymap.unbind(name, true);
    }

    Keys.onPressed: event => {
        event.accepted = true;
        if (event.isAutoRepeat || page.captured(false, event.key))
            return;
        switch (event.key) {
        case Qt.Key_Up:
            page.move(-1);
            break;
        case Qt.Key_Down:
            page.move(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            page.capture(page.abilityAt(page.cursor), false);
            break;
        case Qt.Key_Delete:
        case Qt.Key_Backspace:
            page.clearRow();
            break;
        case Qt.Key_Escape:
        case Qt.Key_Back:
            page.closed();
            break;
        default:
            break;
        }
    }
    Keys.onReleased: event => event.accepted = true

    // The pad's whole vocabulary here. Controller events ignore focus entirely,
    // so Main hands them over explicitly while the page is up.
    function padPressed(code: int) {
        if (page.captured(true, code))
            return;
        switch (code) {
        case Gamepad.Button.DpadUp:
            page.move(-1);
            break;
        case Gamepad.Button.DpadDown:
            page.move(1);
            break;
        case Gamepad.Button.South:
            page.capture(page.abilityAt(page.cursor), true);
            break;
        case Gamepad.Button.West:
            page.clearRow();
            break;
        case Gamepad.Button.North:
            page.resetAll();
            break;
        case Gamepad.Button.East:
        case Gamepad.Button.Start:
            page.closed();
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

        anchors.left: parent.left
        anchors.top: parent.top
        anchors.margins: 28
        text: qsTr("CONTROLS")
        color: Style.theme.textHeading
        font.pixelSize: 18
        font.bold: true
        font.letterSpacing: 2
    }

    // Said plainly rather than pretended: in a browser refusing storage, or a
    // build with no application identity, rebinds last the session only.
    Text {
        anchors.left: heading.right
        anchors.leftMargin: 16
        anchors.baseline: heading.baseline
        visible: !page.keymap.available
        text: qsTr("this session only — controls cannot be saved here")
        color: Style.theme.warn
        font.pixelSize: 12
    }

    Rectangle {
        id: rule

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: heading.bottom
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 10
        height: 1
        color: Style.theme.frameInner
    }

    Flickable {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: rule.bottom
        anchors.bottom: footer.top
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        clip: true
        contentHeight: rows.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: rows

            width: parent.width
            spacing: 4

            Repeater {
                model: page.loadout

                BindingRow {
                    required property AbilitySlot modelData
                    required property int index

                    width: rows.width
                    slot: modelData
                    selected: page.cursor === index
                    onPicked: page.cursor = index
                }
            }
        }
    }

    Column {
        id: footer

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 28
        spacing: 10

        Row {
            spacing: 24

            Choice {
                text: page.resetArmed ? qsTr("PRESS AGAIN TO CONFIRM") : qsTr("RESET ALL")
                alarming: page.resetArmed
                onTapped: page.resetAll()
            }

            Choice {
                text: qsTr("DONE")
                onTapped: page.closed()
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

        signal picked

        readonly property string ability: row.slot.def ? row.slot.def.name : ""

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
            anchors.left: parent.left
            anchors.leftMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: row.slot.def ? row.slot.def.label : ""
            color: row.selected ? Style.theme.textBright : Style.theme.textPrimary
            font.pixelSize: 14
            font.bold: true
            font.letterSpacing: 1
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            Cap {
                ability: row.ability
                pad: false
                label: page.keymap.keyLabel(page.keymap.keyFor(row.ability))
                onPicked: row.picked()
            }

            Cap {
                ability: row.ability
                pad: true
                label: page.keymap.buttonLabel(page.keymap.buttonFor(row.ability))
                onPicked: row.picked()
            }
        }
    }

    // One rebindable control: what is bound now, and a tap to capture the next
    // control pressed onto it.
    component Cap: ControlCap {
        id: cap

        required property string ability
        required property bool pad

        signal picked

        waiting: cap.ability !== "" && page.capturing === cap.ability && page.capturingPad === cap.pad
        displaced: cap.ability !== "" && page.keymap.displaced === cap.ability && page.keymap.displacedPad === cap.pad

        MouseArea {
            anchors.fill: parent
            onClicked: {
                cap.picked();
                page.capture(cap.ability, cap.pad);
            }
        }
    }

    // A plain text action in the footer.
    component Choice: Text {
        id: choice

        property bool alarming: false

        signal tapped

        color: choice.alarming ? Style.theme.warn : Style.theme.accent
        font.pixelSize: 13
        font.bold: true
        font.letterSpacing: 1

        MouseArea {
            anchors.fill: parent
            onClicked: choice.tapped()
        }
    }
}
