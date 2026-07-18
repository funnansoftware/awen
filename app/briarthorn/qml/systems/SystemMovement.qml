import awen.entity
import awen.gamepad

// Folds keyboard, left-stick and d-pad state into the marker position each
// tick, scaled by frame time so the speed is framerate-independent.
System {
    id: movement

    // Movement bounds: the marker is clamped to [0, xMax] x [0, yMax].
    required property real xMax
    required property real yMax

    readonly property real speed: 260 // px per second at full deflection
    readonly property real deadzone: 0.15 // ignore stick jitter around rest

    // Keyboard, left-stick and d-pad state, written by the scene's input
    // handlers and folded together in update().
    property var held: ({})
    property var dpad: ({})
    property real padX: 0
    property real padY: 0

    // The marker position this system acts on; starts centered.
    property real markerX: movement.xMax / 2
    property real markerY: movement.yMax / 2

    function down(...keys): bool {
        return keys.some(key => movement.held[key] === true);
    }
    function padDown(...buttons): bool {
        return buttons.some(button => movement.dpad[button] === true);
    }
    function deaden(v: real): real {
        return Math.abs(v) < movement.deadzone ? 0 : v;
    }

    function update(dt: real) {
        const kx = (movement.down(Qt.Key_D, Qt.Key_Right) ? 1 : 0) - (movement.down(Qt.Key_A, Qt.Key_Left) ? 1 : 0);
        const ky = (movement.down(Qt.Key_S, Qt.Key_Down) ? 1 : 0) - (movement.down(Qt.Key_W, Qt.Key_Up) ? 1 : 0);
        const px = (movement.padDown(Gamepad.Button.DpadRight) ? 1 : 0) - (movement.padDown(Gamepad.Button.DpadLeft) ? 1 : 0);
        const py = (movement.padDown(Gamepad.Button.DpadDown) ? 1 : 0) - (movement.padDown(Gamepad.Button.DpadUp) ? 1 : 0);
        const dx = Math.max(-1, Math.min(1, kx + movement.padX + px));
        const dy = Math.max(-1, Math.min(1, ky + movement.padY + py));
        movement.markerX = Math.max(0, Math.min(movement.xMax, movement.markerX + (dx * movement.speed * dt)));
        movement.markerY = Math.max(0, Math.min(movement.yMax, movement.markerY + (dy * movement.speed * dt)));
    }
}
