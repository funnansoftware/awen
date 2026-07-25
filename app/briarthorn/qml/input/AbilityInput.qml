import QtQml
import awen.command
import awen.input
import "../commands"
import "../database"

// The input wiring for one carried ability: the key and the controller button
// the keymap names fold into a 0..1 axis, and its rising edge posts the
// invocation once per press. One of these per slot in the loadout — the whole
// of what an ability used to cost in hand-written blocks in Main.qml. The code
// lists bind through the keymap, so a rebind re-pushes them onto these very
// objects rather than rebuilding anything, and the axis is owned here, so a
// torn-down binding takes its contribution with it.
QtObject {
    id: input

    // The ability this fires, the keymap it binds through, and the bus its
    // record goes out on.
    required property Ability def
    required property Keymap keymap
    required property CommandQueue queue

    // The name this binds and posts under. Empty for a slot carrying no
    // definition, which then binds nothing and can never fire — a loadout typo
    // must not reach into the keymap or the bus.
    readonly property string ability: input.def ? input.def.name : ""

    readonly property Axis control: Axis {
        id: trigger

        minimum: 0
        onValueChanged: if (trigger.value > 0.5)
            input.invoke.post()
    }

    readonly property ActionKey keys: ActionKey {
        control: input.control
        positive: input.keymap.keyCodes(input.ability)
    }

    readonly property ActionButton pad: ActionButton {
        control: input.control
        positive: input.keymap.buttonCodes(input.ability)
    }

    readonly property CommandAbility invoke: CommandAbility {
        queue: input.queue
        ability: input.ability
    }
}
