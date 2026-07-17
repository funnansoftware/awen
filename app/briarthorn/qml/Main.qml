import QtQuick

// Placeholder shell for the briarthorn game — deliberately pure QML, no C++
// game logic. A marker you steer with WASD / arrow keys over the scope, with a
// live idle pulse so the scene reads as running even at rest. The game grows
// from here.
Window {
    id: root

    width: 800
    height: 600
    visible: true
    title: qsTr("briarthorn")
    color: "#505050" // the scope background

    Item {
        id: scene
        anchors.fill: parent
        focus: true // route the window's keys (WASD / arrows) here

        readonly property real speed: 260 // px per second while a key is held

        property real markerX: width / 2
        property real markerY: height / 2
        property var held: ({})

        function down(...keys): bool {
            return keys.some(key => scene.held[key] === true);
        }

        Keys.onPressed: (event) => {
            if (event.isAutoRepeat)
                return;
            scene.held[event.key] = true;
            event.accepted = true;
        }
        Keys.onReleased: (event) => {
            if (event.isAutoRepeat)
                return;
            scene.held[event.key] = false;
            event.accepted = true;
        }

        // The frame loop: fold the held keys into the marker position once per
        // presented frame, scaled by the real time since the last frame so the
        // speed is framerate-independent.
        FrameAnimation {
            running: true
            onTriggered: {
                const dt = frameTime;
                const dx = (scene.down(Qt.Key_D, Qt.Key_Right) ? 1 : 0) - (scene.down(Qt.Key_A, Qt.Key_Left) ? 1 : 0);
                const dy = (scene.down(Qt.Key_S, Qt.Key_Down) ? 1 : 0) - (scene.down(Qt.Key_W, Qt.Key_Up) ? 1 : 0);
                scene.markerX = Math.max(0, Math.min(scene.width, scene.markerX + (dx * scene.speed * dt)));
                scene.markerY = Math.max(0, Math.min(scene.height, scene.markerY + (dy * scene.speed * dt)));
            }
        }

        // The player marker: an orange heading-up triangle, with an expanding
        // ring behind it that pulses forever so the scene is visibly live.
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
                    NumberAnimation { from: 0.4; to: 0.0; duration: 1500; easing.type: Easing.OutQuad }
                    PauseAnimation { duration: 250 }
                }
                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.5; to: 1.8; duration: 1500; easing.type: Easing.OutQuad }
                    PauseAnimation { duration: 250 }
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
            text: qsTr("WASD or arrow keys to move")
            color: "#99ffffff"
            font.pixelSize: 14
        }
    }
}
