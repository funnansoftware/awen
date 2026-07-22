import QtQuick
import awen.command
import awen.entity
import awen.gamepad
import awen.input
import awen.shapes
import "commands"
import "model"
import "scenarios"
import "systems"
import "themes"
import "ui"

// The briarthorn 1v1 duel, pure QML: ownship pinned to the scope centre and
// flown with WASD / arrows or a gamepad, versus one pursuing hostile
// fighter. Player intent travels as command records — inputs fold into axes,
// standing verbs post records, the game store consumes them — while the
// simulation systems write the entities directly each tick. The
// scope is a radar picture — ownship's detection system builds tracks
// (azimuth and range in the observer's frame) and the view plots those,
// heading-up, through the range projection.
Window {
    id: root

    width: 1280
    height: 720
    visible: true
    // On wasm, fill the web shell's container div exactly — frameless, because Qt
    // otherwise paints its own title bar inside the embedded view.
    visibility: Qt.platform.os === "wasm" ? Window.Maximized : Window.Windowed
    flags: Qt.platform.os === "wasm" ? Qt.FramelessWindowHint : Qt.Window
    title: qsTr("briarthorn")
    color: Style.theme.windowBackground

    // Focus loss swallows key and touch releases, so drop all held input with
    // it: reset the action bindings and zero the stick's own axis slots, which
    // sit outside the router.
    onActiveChanged: if (!active) {
        actions.reset();
        axisSteer.invoke(0);
        axisThrottle.invoke(0);
    }

    // Scope geometry: the centre dropped toward the bottom so the forward
    // sector gets the space. The view pins ownship here.
    readonly property real scopeCenterX: width / 2
    readonly property real scopeCenterY: height * 0.875

    // How world metres project onto the scope: the outer ring's edge sits
    // 0.8 shortSide from the centre and spans the projection's range.
    readonly property real pxPerMeter: projection.pixelsPerMeter(Math.min(width, height) * 0.8)

    // Everything the simulation integrates: the player's craft plus the
    // current scenario's entities.
    readonly property list<Entity> entities: [game.ownship, ...scenario.entities]

    RangeProjection {
        id: projection
        step: 2 // the 40 / 80 km picture
    }

    RangeRing {
        anchors.fill: parent
        centerY: root.scopeCenterY
        radius: projection.innerRange * root.pxPerMeter
        strokeWidth: 2
        gapLength: parent.width * (1 / 32)
        gapAngle: 20
        range: projection.innerRangeKm
        enableTicks: false
    }

    RangeRing {
        anchors.fill: parent
        centerY: root.scopeCenterY
        radius: projection.range * root.pxPerMeter
        strokeWidth: 2
        gapLength: parent.width * (1 / 32)
        gapAngle: 20
        range: projection.rangeKm
        tickOffset: -game.ownship.heading
    }

    Item {
        id: scene
        anchors.fill: parent
        focus: true // route the window's keys (WASD / arrows) here

        property bool padConnected: false

        // The input layer: keys, controller and (later) touch all fold into
        // these axes through the action bindings below.
        Axis {
            id: axisSteer
        }

        Axis {
            id: axisThrottle
            minimum: 0
        }

        Actions {
            id: actions

            ActionKey {
                control: axisSteer
                positive: [Qt.Key_D, Qt.Key_Right]
                negative: [Qt.Key_A, Qt.Key_Left]
            }

            ActionKey {
                control: axisThrottle
                positive: [Qt.Key_W, Qt.Key_Up]
            }

            ActionButton {
                control: axisSteer
                positive: [Gamepad.Button.DpadRight]
                negative: [Gamepad.Button.DpadLeft]
            }

            ActionButton {
                control: axisThrottle
                positive: [Gamepad.Button.DpadUp]
            }
            ActionAxis {
                control: axisSteer
                axis: Gamepad.Axis.LeftX
            }
            ActionAxis {
                control: axisThrottle
                axis: Gamepad.Axis.LeftY
                scale: -1 // stick forward throttles up
            }
        }

        // The standing verbs: each axis edge posts one coalesced record, and
        // touch controls or tests can post the same records straight to the bus.
        CommandSteer {
            queue: bus
            value: axisSteer.value
            onValueChanged: post()
        }

        CommandThrottle {
            queue: bus
            value: axisThrottle.value
            onValueChanged: post()
        }

        // The input handlers only route events into the action map; only
        // mapped keys are consumed.
        Keys.onPressed: event => {
            if (!event.isAutoRepeat)
                event.accepted = actions.keyPressed(event.key);
        }
        Keys.onReleased: event => {
            if (!event.isAutoRepeat)
                event.accepted = actions.keyReleased(event.key);
        }

        // Gamepad input via awen.gamepad; these fire regardless of focus. On wasm
        // the browser refreshes gamepad state once per frame, so poll at 16ms there.
        Gamepad.pollInterval: Qt.platform.os === "wasm" ? 16 : 8
        Gamepad.onConnected: deviceId => scene.padConnected = true
        Gamepad.onDisconnected: deviceId => scene.padConnected = false
        Gamepad.onAxisChanged: (deviceId, axis, value) => actions.axisMoved(axis, value)
        Gamepad.onButtonPressed: (deviceId, button) => actions.buttonPressed(button)
        Gamepad.onButtonReleased: (deviceId, button) => actions.buttonReleased(button)

        // Run order is the lifetimes and the data flow: publish the batch,
        // consume player intent into the game store, run the scenario's own
        // systems, then integrate poses and sweep the radar.
        Systems {
            CommandQueue {
                id: bus
            }

            StoreGame {
                id: game
                queue: bus
            }

            ScenarioDuel {
                id: scenario
                ownship: game.ownship
            }

            SystemMovement {
                entities: root.entities
            }

            SystemDetection {
                id: detection
                observer: game.ownship
                entities: root.entities
            }
        }

        // Ownship's radar volume: a wedge off the nose — always straight up
        // on this heading-up scope — reaching the sensor's detection range.
        ShapeSector {
            anchors.fill: parent
            centerX: root.scopeCenterX
            centerY: root.scopeCenterY
            angleAt: 0
            angleSpan: game.ownship.radarFov
            radius: game.ownship.sensor * root.pxPerMeter
            fillColor: Style.theme.gaugeTrack
        }

        // The track picture: every contact plotted at its azimuth and range,
        // the whole picture rotated into ownship's heading-up frame.
        ViewTracks {
            anchors.fill: parent
            centerX: root.scopeCenterX
            centerY: root.scopeCenterY
            pxPerMeter: root.pxPerMeter
            viewRotation: -game.ownship.heading
            tracks: detection.tracks
        }

        // Ownship, pinned at the scope centre, nose up by construction.
        Symbol {
            x: root.scopeCenterX - width / 2
            y: root.scopeCenterY - height / 2
            classification: game.ownship.classification
            side: game.ownship.side
            showLabel: false
        }

        // The pulsing ring marking ownship, fixed at the scope centre the
        // camera pins it to.
        Rectangle {
            x: root.scopeCenterX - width / 2
            y: root.scopeCenterY - height / 2
            width: 48
            height: width
            radius: width / 2
            color: "transparent"
            border.color: Style.theme.factionOwnship
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

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            text: qsTr("drag the stick, or W to thrust & A/D to turn — arrows, gamepad too")
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

        // The on-screen stick: another source folding into the same axes — its x
        // steers, forward throttles. It contributes under the axis key, summed
        // with keys and the pad, so release must zero it back out.
        Joystick {
            id: stick
            implicitWidth: root.width * 0.125
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 24
            onValueXChanged: axisSteer.invoke(valueX)
            // The stick has no reverse, so a downward pull must not subtract
            // from a throttle another source (keys, pad) is holding up.
            onValueYChanged: axisThrottle.invoke(Math.max(0, valueY))
            onActiveChanged: if (!active) {
                axisSteer.invoke(0);
                axisThrottle.invoke(0);
            }
        }
    }
}
