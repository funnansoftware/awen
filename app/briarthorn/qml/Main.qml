import QtQuick
import awen.buildinfo
import awen.command
import awen.entity
import awen.gamepad
import awen.input
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

    // Everything the simulation integrates: the player's craft plus the
    // current scenario's entities.
    readonly property list<Entity> entities: [game.ownship, ...scenario.entities]

    // The one display projection both scopes share: ranging in or out moves the
    // centre attack scope and the corner minimap together.
    RangeProjection {
        id: projection
        step: 2 // the 40 / 80 km picture
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

            SystemFuel {
                entity: game.ownship
            }

            SystemDetection {
                id: detection
                observer: game.ownship
                entities: root.entities
            }
        }

        // The attack scope: the game's main centre display. Rings, ownship's
        // radar cone, the heading-up track picture and ownship pinned at the
        // dropped centre — all composed by ViewSituation on the shared
        // projection.
        ViewSituationAttack {
            anchors.fill: parent
            projection: projection
            observer: game.ownship
            tracks: detection.tracks
            symbolSize: height * 0.08
        }

        // The full-width top band: persistent meta-game state (the credit purse)
        // and the build version. The corner instruments hang below it.
        ViewTopBar {
            id: topBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            credits: game.credits
            version: "v" + BuildInfo.version
        }

        // Ownship condition readout, top-left: a round dual-arc gauge (hull +
        // fuel) sized to the minimap opposite, so the two round instruments read
        // as a matched, compact pair. Dropped below the top band.
        ViewStatus {
            width: Math.min(root.width, root.height) * 0.22
            height: width
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: topBar.bottom
            anchors.topMargin: 12
            ownship: game.ownship
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 24
            text: qsTr("drag the stick, or W to thrust & A/D to turn — arrows, gamepad too")
            color: "#99ffffff"
            font.pixelSize: 14
        }

        // The on-screen stick: another source folding into the same axes — its x
        // steers, forward throttles. It contributes under the axis key, summed
        // with keys and the pad, so release must zero it back out.
        Joystick {
            id: stick
            implicitWidth: root.width * 0.125
            // Touch play only: the on-screen stick shows on phones, tablets and
            // touch browsers, and stays hidden where keys and a gamepad already
            // drive the axes.
            visible: TouchScreen.available
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

        // The corner minimap, top-right — mirroring the round condition gauge in
        // the opposite corner. The same situation display, stripped to a clean
        // overview. It shares the attack scope's projection, so it ranges with
        // it. Off-scale contacts pin to the rim and an opaque disc backs the
        // picture, masking anything outside the view from rendering over the
        // scope beneath it.
        ViewSituation {
            id: minimap
            width: Math.min(root.width, root.height) * 0.22
            height: width
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: topBar.bottom
            anchors.topMargin: 12

            projection: projection
            observer: game.ownship
            tracks: detection.tracks

            radiusFraction: 0.45
            symbolSize: height * 0.08
            backgroundColor: Style.theme.windowBackground
            rimClamp: true
            closedRings: true
            showNorth: true
            showInnerRing: false
            showTicks: false
            showRadarCone: true
            showOwnshipPulse: false
            showTrackLabels: false
        }

        // The controller lamp, tucked under the minimap on the right; lights up
        // when a controller is connected, so the gamepad path is visible.
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.top: minimap.bottom
            anchors.topMargin: 6
            text: qsTr("controller connected")
            color: "#66bfff"
            font.pixelSize: 13
            visible: scene.padConnected
        }
    }
}
