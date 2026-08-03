pragma ComponentBehavior: Bound

import QtQuick
import "../input"
import "../model"

// The desktop ability rack: one square button per ability the flown craft
// carries, each topped with the control that fires it right now — a key cap
// while the player is on the keyboard, the controller's own button glyph the
// moment a pad takes over. The touch rack's counterpart, and shown in its place
// wherever a keyboard or a controller is driving; the caller docks it in the
// same corner the touch arc uses, so the abilities stay put as the HUD swaps
// devices and the scope's centre column — ownship, its pulse, and the sector a
// pursuer converges through — is never drawn over. Nothing here names an
// ability: the rack is the loadout, so a craft carrying a new one grows a
// button for it.
Row {
    id: root

    // The keymap the caps read, the flown craft's live loadout, and which
    // device the player is on — the caps follow all three.
    required property Keymap keymap
    required property list<AbilitySlot> loadout
    required property ActiveDevice device

    // Button side asked for; they are square, so this is both extents.
    property real buttonSize: 74

    // The widest the whole rack may draw, or -1 for no ceiling. The rack is
    // docked in a corner and must never reach into ownship's column, so the
    // caller hands it the span it may fill and the buttons shrink to fit
    // rather than the loadout pushing the rack across the scope. A floor under
    // the shrink keeps a caption legible; a rack that would breach it has
    // outgrown the corner and says so rather than silently vanishing.
    property real maximumWidth: -1
    property real minimumButtonSize: 44

    readonly property int count: root.loadout.length

    // What the buttons actually draw at, once the ceiling is applied.
    readonly property real side: {
        if (root.maximumWidth < 0 || root.count === 0)
            return root.buttonSize;
        const fit = (root.maximumWidth - root.spacing * (root.count - 1)) / root.count;
        return Math.max(root.minimumButtonSize, Math.min(root.buttonSize, fit));
    }

    // Carries the pressed ability's name out, so the row stays a control and
    // never touches the bus, and reports a press that came from a thumb, so the
    // HUD can hand the interface back to the touch controls.
    signal invoked(string ability)
    signal touched

    spacing: 8

    Repeater {
        model: root.loadout

        AbilityButton {
            id: button

            required property AbilitySlot modelData

            readonly property string ability: button.modelData.def ? button.modelData.def.name : ""

            width: root.side
            height: width

            label: button.modelData.def ? button.modelData.def.label : ""
            charges: button.modelData.charges
            ready: button.modelData.ready
            // The cooldown as a fraction of this ability's own, so a long
            // reload and a short one both wind the bar over its full sweep.
            cooling: button.modelData.def && button.modelData.def.cooldown > 0 ? button.modelData.cooldownRemaining / button.modelData.def.cooldown : 0

            // The cap follows the device in the player's hands: the pad's own
            // button while a controller is driving, the key otherwise.
            pad: root.device.pad
            code: root.device.pad ? root.keymap.buttonFor(button.ability) : -1
            control: root.device.pad ? root.keymap.buttonLabel(root.keymap.buttonFor(button.ability)) : root.keymap.keyLabel(root.keymap.keyFor(button.ability))

            // A slot carrying no definition binds nothing and fires nothing —
            // a loadout typo must not reach the bus.
            onTapped: if (button.modelData.def)
                root.invoked(button.ability)
            onTouched: root.touched()
        }
    }
}
