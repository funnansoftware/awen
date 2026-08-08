pragma ComponentBehavior: Bound

import QtQuick
import awen.gamepad
import awen.input
import "../input"
import "../model"
import "../themes"

// The settings page: the palette the game draws in, then one row per ability the
// flown craft carries, showing the key and the controller button that invoke it
// and rebound by picking a cap and pressing the control you want. Full-bleed and
// opaque, because the duel is stopped behind it, scrolling because a phone in
// landscape has room for about three rows, and driveable from a pad, so a
// controller player can reach every row without a keyboard.
//
// A sibling of the game scene rather than a child: a key it declines bubbles to
// the window instead of falling sideways into the scene's handler. Main owns
// opening and closing it, and focus follows open on both sides declaratively.
Item {
    id: root

    // The table being edited and the flown craft's live loadout: the binding
    // rows are exactly the abilities this airframe carries, so there are no
    // dead ones.
    required property Keymap keymap
    required property list<AbilitySlot> loadout

    // Which device the player is driving with; the page's keys report in, as
    // the pad route already does, so a keyboard rebind swaps the HUD's caps.
    required property ActiveDevice device

    // Whether the page is up. Main drives this; focus and the pause follow it.
    property bool open: false

    // The ability waiting for a control and the device it waits on; the name is
    // empty when nothing is capturing.
    property string capturing: ""
    property bool capturingPad: false

    // The highlighted row, for keyboard and pad navigation, and whether the
    // control reset is armed — it discards every rebind, so it takes two
    // presses.
    property int cursor: 0
    property bool resetArmed: false

    signal closed

    // Every row the cursor walks, display first and then controls, as one flat
    // list. A cursor index means the same thing to the highlight, the keyboard
    // and the pad, and — because each record carries only what its own kind has
    // — a display row simply has no ability for the binding verbs to act on.
    readonly property var rows: {
        const list = [];
        for (let i = 0; i < Style.themes.length; ++i)
            list.push({
                theme: Style.themes[i],
                slot: null
            });
        for (let i = 0; i < root.loadout.length; ++i)
            list.push({
                theme: null,
                slot: root.loadout[i]
            });
        return list;
    }

    // Where the binding rows start, so each section's delegate can name its own
    // place in the flat list.
    readonly property int themeCount: Style.themes.length

    // The ability under the cursor, empty on a display row: every verb that acts
    // on a binding reads it, so those rows refuse them all without a test of
    // their own.
    readonly property string ability: {
        const row = root.rows[root.cursor];
        return row && row.slot && row.slot.def ? row.slot.def.name : "";
    }

    visible: root.open
    focus: root.open

    onOpenChanged: {
        root.capturing = "";
        root.resetArmed = false;
        root.keymap.displaced = "";
        root.select(0);
        scroll.contentY = 0;
    }

    // A loadout rebuilt under the page — a new duel, a new craft — can leave the
    // cursor past the end.
    onRowsChanged: if (root.cursor >= root.rows.length)
        root.select(Math.max(0, root.rows.length - 1))

    Keys.onPressed: event => {
        event.accepted = true;
        // Any key here is keyboard flying, reported ahead of the dispatch the
        // way Main reports the pad ahead of padPressed.
        root.device.kind = ActiveDevice.Keyboard;
        if (event.isAutoRepeat || root.captured(false, event.key))
            return;
        switch (event.key) {
        case Qt.Key_Up:
        case Qt.Key_W:
            root.move(-1);
            break;
        case Qt.Key_Down:
        case Qt.Key_S:
            root.move(1);
            break;
        case Qt.Key_Return:
        case Qt.Key_Enter:
            root.chose(false);
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

    // The left stick steps the cursor once per push, as it does on the launch
    // and pause screens: the axis's rest band re-arms on return to centre, so a
    // held stick never runs down the list.
    Axis {
        id: navAxis
        onStepped: direction => root.move(direction)
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

        text: qsTr("SETTINGS")
        color: Style.theme.textHeading
        anchors { left: parent.left; top: parent.top; margins: 28 }
        font { pixelSize: 18; bold: true; letterSpacing: 2 }
    }

    // Said plainly rather than pretended: in a browser refusing storage, or a
    // build with no application identity, everything on this page lasts the
    // session only. The keymap's own test speaks for the theme too — it is one
    // process-wide fact about the settings store, not a fact about bindings.
    Text {
        visible: !root.keymap.available
        text: qsTr("this session only — settings cannot be saved here")
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
        id: scroll

        clip: true
        contentHeight: column.implicitHeight
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

        // Brings a row fully into view, for the players who move the cursor
        // without touching the list. Clamped by hand: boundsBehavior governs
        // dragging and flicking, not a write to contentY, so a page shorter
        // than its viewport would otherwise scroll to a negative offset with
        // nothing left to pull it back.
        function reveal(top: real, rowHeight: real) {
            const viewport = Math.max(0, scroll.height);
            const limit = Math.max(0, scroll.contentHeight - viewport);
            if (top < scroll.contentY)
                scroll.contentY = Math.min(limit, Math.max(0, top));
            else if (top + rowHeight > scroll.contentY + viewport)
                scroll.contentY = Math.min(limit, Math.max(0, top + rowHeight - viewport));
        }

        Column {
            id: column

            width: parent.width
            spacing: 4

            Section {
                text: qsTr("DISPLAY")
            }

            Repeater {
                model: Style.themes

                ThemeRow {
                    required property Theme modelData
                    required property int index

                    width: column.width
                    theme: modelData
                    rowIndex: index
                }
            }

            Section {
                text: qsTr("CONTROLS")
            }

            Repeater {
                model: root.loadout

                BindingRow {
                    required property AbilitySlot modelData
                    required property int index

                    width: column.width
                    slot: modelData
                    rowIndex: root.themeCount + index
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
                text: root.resetArmed ? qsTr("PRESS AGAIN TO CONFIRM") : qsTr("RESET CONTROLS")
                alarming: root.resetArmed
                onTapped: root.resetAll()
            }

            Choice {
                text: qsTr("DONE")
                onTapped: root.closed()
            }
        }

        Text {
            width: footer.width
            wrapMode: Text.WordWrap
            text: qsTr("↑↓ select · ENTER choose · DEL clear · ESC back      pad: D-pad select · A choose · X clear · Y default controls · B back")
            color: Style.theme.textMuted
            font.pixelSize: 12
        }
    }

    // A section's caption, over the rows it gathers.
    component Section: Text {
        topPadding: 12
        color: Style.theme.textLabel
        font { pixelSize: 11; bold: true; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
    }

    // What every row shares: the highlight, the hit target that takes it, and
    // the scroll that follows it.
    component PageRow: Rectangle {
        id: page

        // This row's place in the flat list — what the cursor holds.
        required property int rowIndex
        readonly property bool selected: root.cursor === page.rowIndex

        implicitHeight: 40
        radius: Style.theme.panelRadius
        color: page.selected ? Style.theme.panelBackground : "transparent"
        border.width: page.selected ? 1 : 0
        border.color: Style.theme.accent

        onSelectedChanged: if (page.selected)
            scroll.reveal(page.y, page.height)
    }

    // One palette on offer: a mark on the one in force, its name, and a strip of
    // its own colours on its own background, so the choice can be read before it
    // is taken.
    component ThemeRow: PageRow {
        id: row

        required property Theme theme
        readonly property bool current: Style.theme === row.theme

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.select(row.rowIndex);
                Style.select(row.theme.name);
            }
        }

        // The mark, drawn rather than set in type: no tick character is safe
        // across the four platforms' instrument faces.
        Rectangle {
            width: 12
            height: width
            radius: width / 2
            color: "transparent"
            border.width: 1
            border.color: row.current ? Style.theme.accent : Style.theme.textMuted
            anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }

            Rectangle {
                anchors.centerIn: parent
                visible: row.current
                width: 6
                height: width
                radius: width / 2
                color: Style.theme.accent
            }
        }

        Text {
            text: row.theme.label
            color: row.selected ? Style.theme.textBright : Style.theme.textPrimary
            anchors { left: parent.left; leftMargin: 36; verticalCenter: parent.verticalCenter }
            font { pixelSize: 14; bold: true; letterSpacing: Style.theme.capsTracking }
        }

        // The swatch: the palette's own window colour carrying its own accent
        // and factions, so a row is a small sample of what picking it does.
        Rectangle {
            width: swatches.width + 16
            height: 22
            radius: Style.theme.panelRadius
            color: row.theme.windowBackground
            border.width: 1
            border.color: row.theme.frameInner
            anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }

            Row {
                id: swatches

                spacing: 6
                anchors.centerIn: parent

                Swatch {
                    tint: row.theme.accent
                }
                Swatch {
                    tint: row.theme.factionFriendly
                }
                Swatch {
                    tint: row.theme.factionHostile
                }
                Swatch {
                    tint: row.theme.warn
                }
                Swatch {
                    tint: row.theme.textPrimary
                }
            }
        }
    }

    // One colour in a palette's swatch.
    component Swatch: Rectangle {
        id: swatch

        property color tint: "transparent"

        width: 8
        height: width
        radius: width / 2
        color: swatch.tint
    }

    // One ability's row: its label and one cap per device, either of which is
    // the hit target for a rebind. The whole row selects on touch.
    component BindingRow: PageRow {
        id: row

        required property AbilitySlot slot
        readonly property string ability: row.slot.def ? row.slot.def.name : ""

        MouseArea {
            anchors.fill: parent
            onClicked: root.select(row.rowIndex)
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
                rowIndex: row.rowIndex
                label: root.keymap.keyLabel(root.keymap.keyFor(row.ability))
            }

            Cap {
                ability: row.ability
                rowIndex: row.rowIndex
                pad: true
                code: root.keymap.buttonFor(row.ability)
                label: root.keymap.buttonLabel(root.keymap.buttonFor(row.ability))
            }
        }
    }

    // One rebindable control: what is bound now, and a tap to capture the next
    // control pressed onto it. The device it belongs to is the cap's own pad
    // flag, which is what decides how it draws as well as what it captures.
    component Cap: ControlCap {
        id: cap

        required property string ability
        required property int rowIndex

        waiting: cap.ability !== "" && root.capturing === cap.ability && root.capturingPad === cap.pad
        displaced: cap.ability !== "" && root.keymap.displaced === cap.ability && root.keymap.displacedPad === cap.pad

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.select(cap.rowIndex);
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

    // The one cursor write. A capture belongs to the row it was armed on, so
    // leaving that row stands it down — the keyboard and the pad's own buttons
    // cannot move while capturing (their navigation controls are reserved, so
    // the gate below swallows them), but a mouse can, and an armed capture left
    // behind a highlight that has moved on would bind the next key pressed to
    // an ability the player has forgotten about.
    function select(index: int) {
        if (index !== root.cursor)
            root.capturing = "";
        root.cursor = index;
        root.resetArmed = false;
    }

    // Clamped rather than wrapped: one press at the bottom of a scrolling list
    // would otherwise throw the cursor and the viewport back to the top.
    function move(delta: int) {
        root.select(Math.max(0, Math.min(root.rows.length - 1, root.cursor + delta)));
    }

    // Enter, or the pad's A, on the highlighted row: a display row takes its
    // palette, a binding row starts waiting for a control.
    function chose(pad: bool) {
        const row = root.rows[root.cursor];
        if (!row)
            return;
        if (row.theme)
            Style.select(row.theme.name);
        else
            root.capture(root.ability, pad);
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

    // Two presses, because it throws away every rebind and there is no undo. A
    // page-wide action rather than a row's, so it answers from any row.
    function resetAll() {
        if (root.resetArmed) {
            root.keymap.reset();
            root.resetArmed = false;
            return;
        }
        root.resetArmed = true;
    }

    function clearRow() {
        const name = root.ability;
        root.keymap.unbind(name, false);
        root.keymap.unbind(name, true);
    }

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
            root.chose(true);
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

    // Held out while a row is waiting, which is the gate the coded controls get
    // from captured(): the d-pad cannot move the cursor mid-capture because the
    // keymap reserves it, and the stick — which carries no code and so can be
    // reserved by nothing — would otherwise be the one control on the pad that
    // stands a capture down by being bumped.
    function axisMoved(axis: int, value: real) {
        if (root.capturing === "" && axis === Gamepad.Axis.LeftY)
            navAxis.invoke(value);
    }
}
