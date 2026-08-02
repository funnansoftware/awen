pragma ComponentBehavior: Bound

import QtQuick
import "../input"
import "../model"
import "../themes"

// The control hint line: the fixed flight keys, then one chip per ability the
// flown craft carries, captioned with whatever that ability is bound to right
// now. Nothing here names an ability, so a new one appears the moment a loadout
// carries it and follows every rebind.
Row {
    id: root

    // The keymap the captions read, and the flown craft's live loadout.
    required property Keymap keymap
    required property list<AbilitySlot> loadout

    spacing: 14

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("W thrust · A/D turn · WHEEL range")
        color: Style.theme.textMuted
        font.pixelSize: 13
    }

    Repeater {
        model: root.loadout

        Row {
            id: chip

            required property AbilitySlot modelData

            readonly property string ability: chip.modelData.def ? chip.modelData.def.name : ""

            spacing: 5

            ControlCap {
                anchors.verticalCenter: parent.verticalCenter
                label: root.keymap.keyLabel(root.keymap.keyFor(chip.ability))
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.modelData.def ? chip.modelData.def.label : ""
                color: Style.theme.textLabel
                font { pixelSize: 13; bold: true; letterSpacing: 1 }
            }
        }
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: qsTr("ESC controls")
        color: Style.theme.textMuted
        font.pixelSize: 13
    }
}
