pragma ComponentBehavior: Bound

import QtQuick
import "../model"

// The touch ability rack: one square button per ability the flown craft
// carries, laid along a quarter circle swept from the bottom edge round to the
// right edge, so a thumb pivoting in that corner reaches every one of them
// without the hand leaving the display. The scope's range pair sits at that
// pivot, the one spot the thumb never travels to reach. Nothing here names an
// ability — the rack is the loadout, so a craft carrying a new one grows a
// button for it and a rack of one still lands under the thumb.
Item {
    id: root

    // The flown craft's live loadout, in the order it plots along the arc:
    // first at the bottom edge, last at the right.
    required property list<AbilitySlot> loadout

    // The arc's radius — how far out from the corner the buttons sit.
    property real radius: 150

    readonly property int count: root.loadout.length

    // Degrees between neighbours, spread across the full quarter turn; a lone
    // button sits halfway round it instead.
    readonly property real step: root.count > 1 ? 90 / (root.count - 1) : 0

    // Button side: a thumb-sized target, shrunk to keep neighbours off each
    // other once the arc carries enough of them to crowd.
    readonly property real buttonSize: {
        const spread = root.radius * root.step * Math.PI / 180;
        return root.count > 1 ? Math.min(root.radius * 0.45, spread * 0.85) : root.radius * 0.45;
    }

    // The range arrows: smaller than an ability, because they step a display
    // and cost nothing to press twice, but still a thumb's worth of target.
    readonly property real arrowSize: root.buttonSize * 0.7

    // What the stacked pair spans, and the gap keeping the two discs apart.
    readonly property real arrowGap: root.arrowSize * 0.12
    readonly property real arrowSpan: root.arrowSize * 2 + root.arrowGap

    // The thumb's pivot, inset from the item's corner far enough that
    // everything centred on it lands inside: half a button horizontally, and
    // vertically whichever of the button and the arrow pair reaches further.
    // That is also what makes the implicit size exact.
    readonly property real pivotX: width - root.buttonSize / 2
    readonly property real pivotY: height - Math.max(root.buttonSize, root.arrowSpan) / 2

    // Carries the pressed ability's name out, and the range steps the pair at
    // the pivot asks for; the caller acts on all three, so the rack stays a
    // control and touches neither the bus nor the projection.
    signal invoked(string ability)
    signal rangedIn
    signal rangedOut

    implicitWidth: root.radius + root.buttonSize
    implicitHeight: root.radius + Math.max(root.buttonSize, root.arrowSpan)

    Repeater {
        model: root.loadout

        AbilityButton {
            id: control

            required property int index
            required property AbilitySlot modelData

            // Swept anticlockwise from the bottom edge: 0 lies left of the
            // pivot, 90 directly above it.
            readonly property real bearing: (root.count > 1 ? control.index * root.step : 45) * Math.PI / 180

            width: root.buttonSize
            height: width
            x: root.pivotX - Math.cos(control.bearing) * root.radius - width / 2
            y: root.pivotY - Math.sin(control.bearing) * root.radius - height / 2

            // A thumb on the button is the control; there is nothing to caption
            // it with, so the rack's buttons carry no cap at all.
            showControl: false
            label: control.modelData.def ? control.modelData.def.label : ""
            charges: control.modelData.charges
            ready: control.modelData.ready
            // The cooldown as a fraction of this ability's own, so a long
            // reload and a short one both wind the bar over its full sweep.
            cooling: control.modelData.def && control.modelData.def.cooldown > 0 ? control.modelData.cooldownRemaining / control.modelData.def.cooldown : 0

            // A slot carrying no definition binds nothing and fires nothing —
            // a loadout typo must not reach the bus.
            onTapped: if (control.modelData.def)
                root.invoked(control.modelData.def.name)
        }
    }

    // The range pair, stacked on the pivot the arc is swept around: up ranges
    // in, down ranges out, the same way round as the wheel and the d-pad.
    Column {
        x: root.pivotX - width / 2
        y: root.pivotY - height / 2
        spacing: root.arrowGap

        TouchArrow {
            width: root.arrowSize
            height: width
            up: true
            onTapped: root.rangedIn()
        }

        TouchArrow {
            width: root.arrowSize
            height: width
            up: false
            onTapped: root.rangedOut()
        }
    }
}
