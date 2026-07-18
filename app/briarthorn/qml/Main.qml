import QtQuick
import awen.entity
import awen.gamepad
import "systems"

// Placeholder shell for the briarthorn game, pure QML: a marker steered with
// WASD / arrow keys or a gamepad. The game grows from here.
Window {
    id: root

    width: 800
    height: 600
    visible: true
    // On wasm, fill the web shell's container div exactly — frameless, because Qt
    // otherwise paints its own title bar inside the embedded view.
    visibility: Qt.platform.os === "wasm" ? Window.Maximized : Window.Windowed
    flags: Qt.platform.os === "wasm" ? Qt.FramelessWindowHint : Qt.Window
    title: qsTr("briarthorn")
    color: "#505050" // the scope background

    Item {
        id: scene
        anchors.fill: parent
        focus: true // route the window's keys (WASD / arrows) here

        property bool padConnected: false

        // The input handlers only capture state into the movement system; the
        // runner below folds it into the game once per frame.
        Keys.onPressed: event => {
            if (event.isAutoRepeat)
                return;
            movement.held[event.key] = true;
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (event.isAutoRepeat)
                return;
            movement.held[event.key] = false;
            event.accepted = true;
        }

        // Gamepad input via awen.gamepad; these fire regardless of focus. On wasm
        // the browser refreshes gamepad state once per frame, so poll at 16ms there.
        Gamepad.pollInterval: Qt.platform.os === "wasm" ? 16 : 8
        Gamepad.onConnected: deviceId => scene.padConnected = true
        Gamepad.onDisconnected: deviceId => scene.padConnected = false
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            if (axis === Gamepad.Axis.LeftX)
                movement.padX = movement.deaden(value);
            else if (axis === Gamepad.Axis.LeftY)
                movement.padY = movement.deaden(value);
        }
        Gamepad.onButtonPressed: (deviceId, button) => movement.dpad[button] = true
        Gamepad.onButtonReleased: (deviceId, button) => movement.dpad[button] = false

        // The game's systems, each updating its slice of state every frame.
        Systems {
            SystemMovement {
                id: movement
                xMax: scene.width
                yMax: scene.height
            }
        }

        // The player marker: an orange triangle with a pulsing ring behind it.
        Item {
            x: movement.markerX
            y: movement.markerY

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
