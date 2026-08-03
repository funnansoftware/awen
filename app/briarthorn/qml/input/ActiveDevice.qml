import QtQml
import awen.input

// Which device the player is driving with, and so which controls the HUD draws:
// the touch racks with nothing captioned, the keyboard's key caps, or the
// controller's own button glyphs. Last used rather than what is plugged in — a
// pad left connected while the player flies on the keyboard must not relabel
// every button — and seeded from the hardware, so a phone opens on its thumb
// controls and a desktop on its keys.
//
// Not called InputDevice: QtQuick registers QInputDevice under that name, and a
// directory import does not shadow it for enum reads. A file importing both
// still instantiates this type, so `InputDevice {}` works and the build stays
// green, while `InputDevice.Gamepad` silently reads undefined off Qt's type and
// the assignment throws — taking the rest of the handler with it.
QtObject {
    id: root

    enum Kind {
        Touch,
        Keyboard,
        Gamepad
    }

    // What the player last drove with. Assigned by whichever handler saw the
    // input: the window's key handler, the pad's, and the touch controls' own.
    property int kind: TouchScreen.available ? ActiveDevice.Touch : ActiveDevice.Keyboard

    readonly property bool touch: root.kind === ActiveDevice.Touch
    readonly property bool pad: root.kind === ActiveDevice.Gamepad

    // How far a stick must travel before it counts as being driven. A
    // controller resting off centre streams small values forever, and those
    // must not take the caps off the keyboard the player is flying on.
    readonly property real deflection: 0.5

    // A stick moved: only a deliberate push hands the interface to the pad.
    function moved(value: real) {
        if (Math.abs(value) > root.deflection)
            root.kind = ActiveDevice.Gamepad;
    }
}
