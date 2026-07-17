import QtQuick
import awen.gamepad

// Placeholder shell for the briarthorn game — deliberately pure QML, no C++ game
// logic. A marker you steer with WASD / arrow keys or a gamepad (the awen.gamepad
// module: SDL3 on desktop), over a live idle pulse so the scene reads as running
// even at rest. The game grows from here.
Window {
    id: root

    width: 800
    height: 600
    visible: true
    // On wasm the window maximizes into the container div the web shell hands
    // to qtLoad (web/index.html's game view), filling it exactly; elsewhere it
    // stays a normal 800×600 desktop window. Frameless on wasm: Qt paints its
    // own title bar inside the container otherwise, which reads as a window
    // within the page rather than an embedded view.
    visibility: Qt.platform.os === "wasm" ? Window.Maximized : Window.Windowed
    flags: Qt.platform.os === "wasm" ? Qt.FramelessWindowHint : Qt.Window
    title: qsTr("briarthorn")
    color: "#505050" // the scope background

    Item {
        id: scene
        anchors.fill: parent
        focus: true // route the window's keys (WASD / arrows) here

        readonly property real speed: 260 // px per second at full deflection
        readonly property real deadzone: 0.15 // ignore stick jitter around rest

        property real markerX: width / 2
        property real markerY: height / 2

        // Keyboard held-key set, gamepad left-stick deflection, and gamepad d-pad
        // held-button set — all folded together in the frame loop below.
        property var held: ({})
        property real padX: 0
        property real padY: 0
        property var dpad: ({})
        property bool padConnected: false

        function down(...keys): bool {
            return keys.some(key => scene.held[key] === true);
        }
        function padDown(...buttons): bool {
            return buttons.some(button => scene.dpad[button] === true);
        }
        function deaden(v: real): real {
            return Math.abs(v) < scene.deadzone ? 0 : v;
        }

        Keys.onPressed: event => {
            if (event.isAutoRepeat)
                return;
            scene.held[event.key] = true;
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (event.isAutoRepeat)
                return;
            scene.held[event.key] = false;
            event.accepted = true;
        }

        // Gamepad input via awen.gamepad. Unlike Keys these fire regardless of
        // focus. Backed by SDL3 on desktop and wasm (in the browser SDL wraps
        // the Gamepad API); on android the module is an inert stub, so there
        // these simply never fire and keyboard control stays.
        //
        // Poll cadence, tuned per platform through the attached property (the
        // module's default is 8ms, ~125 Hz): the browser only refreshes gamepad
        // state once per animation frame, so on wasm one frame (16ms) is as
        // fresh as the data gets — polling faster there only re-reads the same
        // snapshot.
        Gamepad.pollInterval: Qt.platform.os === "wasm" ? 16 : 8
        Gamepad.onConnected: deviceId => scene.padConnected = true
        Gamepad.onDisconnected: deviceId => scene.padConnected = false
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            if (axis === Gamepad.Axis.LeftX)
                scene.padX = scene.deaden(value);
            else if (axis === Gamepad.Axis.LeftY)
                scene.padY = scene.deaden(value);
        }
        Gamepad.onButtonPressed: (deviceId, button) => scene.dpad[button] = true
        Gamepad.onButtonReleased: (deviceId, button) => scene.dpad[button] = false

        // The frame loop: fold keyboard, stick and d-pad into the marker position
        // once per presented frame, scaled by the real time since the last frame so
        // the speed is framerate-independent. Y follows screen space (down positive),
        // which is also how SDL reports the stick.
        FrameAnimation {
            running: true
            onTriggered: {
                const dt = frameTime;
                const kx = (scene.down(Qt.Key_D, Qt.Key_Right) ? 1 : 0) - (scene.down(Qt.Key_A, Qt.Key_Left) ? 1 : 0);
                const ky = (scene.down(Qt.Key_S, Qt.Key_Down) ? 1 : 0) - (scene.down(Qt.Key_W, Qt.Key_Up) ? 1 : 0);
                const px = (scene.padDown(Gamepad.Button.DpadRight) ? 1 : 0) - (scene.padDown(Gamepad.Button.DpadLeft) ? 1 : 0);
                const py = (scene.padDown(Gamepad.Button.DpadDown) ? 1 : 0) - (scene.padDown(Gamepad.Button.DpadUp) ? 1 : 0);
                const dx = Math.max(-1, Math.min(1, kx + scene.padX + px));
                const dy = Math.max(-1, Math.min(1, ky + scene.padY + py));
                scene.markerX = Math.max(0, Math.min(scene.width, scene.markerX + (dx * scene.speed * dt)));
                scene.markerY = Math.max(0, Math.min(scene.height, scene.markerY + (dy * scene.speed * dt)));
            }
        }

        // The player marker: an orange heading-up triangle, with an expanding ring
        // behind it that pulses forever so the scene is visibly live.
        Item {
            x: scene.markerX
            y: scene.markerY

            Rectangle {
                anchors.centerIn: parent
                width: 48
                height: width
                radius: width / 2
                color: "transparent"
                border.color: "#ffa100"
                border.width: 2

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0.4
                        to: 0.0
                        duration: 1500
                        easing.type: Easing.OutQuad
                    }
                    PauseAnimation {
                        duration: 250
                    }
                }
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation {
                        from: 0.5
                        to: 1.8
                        duration: 1500
                        easing.type: Easing.OutQuad
                    }
                    PauseAnimation {
                        duration: 250
                    }
                }
            }

            Canvas {
                anchors.centerIn: parent
                width: 26
                height: width

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.fillStyle = "#ffa100";
                    ctx.beginPath();
                    ctx.moveTo(width / 2, 0);      // nose
                    ctx.lineTo(width, height);     // tail right
                    ctx.lineTo(0, height);         // tail left
                    ctx.closePath();
                    ctx.fill();
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            text: qsTr("WASD, arrow keys, or a gamepad to move")
            color: "#99ffffff"
            font.pixelSize: 14
        }

        // Lights up when a controller is connected, so the gamepad path is visible.
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            text: qsTr("controller connected")
            color: "#66bfff"
            font.pixelSize: 13
            visible: scene.padConnected
        }
    }
}
