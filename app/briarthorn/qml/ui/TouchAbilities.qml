pragma ComponentBehavior: Bound

import QtQuick
import "../model"

// The touch ability rack: one round button per ability the flown craft
// carries, laid along a quarter circle swept from the bottom edge round to the
// right edge, so a thumb pivoting in that corner reaches every one of them
// without the hand leaving the display. The stick's counterpart in the
// opposite corner, and like it, only a touch device shows it. Nothing here
// names an ability — the rack is the loadout, so a craft carrying a new one
// grows a button for it and a rack of one still lands under the thumb.
Item {
    id: rack

    // The flown craft's live loadout, in the order it plots along the arc:
    // first at the bottom edge, last at the right.
    required property list<AbilitySlot> loadout

    // The arc's radius — how far out from the corner the buttons sit.
    property real radius: 150

    // Carries the pressed ability's name out; the caller posts the record, so
    // the rack stays a control and never touches the bus.
    signal invoked(string ability)

    readonly property int count: rack.loadout.length

    // Degrees between neighbours, spread across the full quarter turn; a lone
    // button sits halfway round it instead.
    readonly property real step: rack.count > 1 ? 90 / (rack.count - 1) : 0

    // Button diameter: a thumb-sized target, shrunk to keep neighbours off each
    // other once the arc carries enough of them to crowd.
    readonly property real buttonSize: {
        const spread = rack.radius * rack.step * Math.PI / 180;
        return rack.count > 1 ? Math.min(rack.radius * 0.45, spread * 0.85) : rack.radius * 0.45;
    }

    // The thumb's pivot, a button's half-width in from the item's corner: the
    // buttons ending the arc then land inside the item rather than straddling
    // its edges, which is also what makes the implicit size exact.
    readonly property real pivotX: width - rack.buttonSize / 2
    readonly property real pivotY: height - rack.buttonSize / 2

    implicitWidth: rack.radius + rack.buttonSize
    implicitHeight: implicitWidth

    Repeater {
        model: rack.loadout

        TouchButton {
            id: control

            required property int index
            required property AbilitySlot modelData

            // Swept anticlockwise from the bottom edge: 0 lies left of the
            // pivot, 90 directly above it.
            readonly property real bearing: (rack.count > 1 ? control.index * rack.step : 45) * Math.PI / 180

            width: rack.buttonSize
            height: width
            x: rack.pivotX - Math.cos(control.bearing) * rack.radius - width / 2
            y: rack.pivotY - Math.sin(control.bearing) * rack.radius - height / 2

            label: control.modelData.def ? control.modelData.def.label : ""
            charges: control.modelData.charges
            ready: control.modelData.ready
            // The cooldown as a fraction of this ability's own, so a long
            // reload and a short one both wind the rim over their full sweep.
            cooling: control.modelData.def && control.modelData.def.cooldown > 0 ? control.modelData.cooldownRemaining / control.modelData.def.cooldown : 0

            // A slot carrying no definition binds nothing and fires nothing —
            // a loadout typo must not reach the bus.
            onTapped: if (control.modelData.def)
                rack.invoked(control.modelData.def.name)
        }
    }
}
