import awen.entity
import awen.gamepad
import "../model"

// Folds keyboard, left-stick and d-pad state into the flown entity's control
// inputs each tick: A/D (stick X, d-pad left/right) steer, W/up (stick up,
// d-pad up) throttle.
System {
    id: pilot

    // The entity being flown.
    required property Entity entity

    readonly property real deadzone: 0.15 // ignore stick jitter around rest

    // Keyboard, left-stick and d-pad state, written by the scene's input
    // handlers and folded together in update().
    property var held: ({})
    property var dpad: ({})
    property real padX: 0
    property real padY: 0

    function down(...keys): bool {
        return keys.some(key => pilot.held[key] === true);
    }
    function padDown(...buttons): bool {
        return buttons.some(button => pilot.dpad[button] === true);
    }
    function deaden(v: real): real {
        return Math.abs(v) < pilot.deadzone ? 0 : v;
    }

    function update(dt: real) {
        const keySteer = (pilot.down(Qt.Key_D, Qt.Key_Right) ? 1 : 0) - (pilot.down(Qt.Key_A, Qt.Key_Left) ? 1 : 0);
        const padSteer = (pilot.padDown(Gamepad.Button.DpadRight) ? 1 : 0) - (pilot.padDown(Gamepad.Button.DpadLeft) ? 1 : 0);
        const keyThrottle = pilot.down(Qt.Key_W, Qt.Key_Up) ? 1 : 0;
        const padThrottle = pilot.padDown(Gamepad.Button.DpadUp) ? 1 : 0;
        pilot.entity.commandedSteer = Math.max(-1, Math.min(1, keySteer + padSteer + pilot.padX));
        pilot.entity.commandedThrottle = Math.max(0, Math.min(1, keyThrottle + padThrottle - pilot.padY));
    }
}
