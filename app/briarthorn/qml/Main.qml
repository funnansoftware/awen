import QtQuick
import awen.entity
import awen.gamepad
import "model"
import "systems"
import "themes"
import "ui"

// The briarthorn 1v1 duel, pure QML: ownship pinned to the scope centre and
// flown with WASD / arrows or a gamepad, the world drawn heading-up around
// it, versus one pursuing hostile fighter.
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

    // Scope geometry: the centre dropped toward the bottom so the forward
    // sector gets the space (briardart's attack scope, verticalShift 0.375 /
    // viewScale 1.6). The camera pins ownship here.
    readonly property real scopeCenterX: width / 2
    readonly property real scopeCenterY: height * 0.875

    RangeRing {
        anchors.fill: parent
        centerY: root.scopeCenterY
        radius: Math.min(width, height) * 0.4
        strokeWidth: 2
        gapLength: parent.width * (1 / 32)
        gapAngle: 20
        range: 40
        enableTicks: false
    }

    RangeRing {
        anchors.fill: parent
        centerY: root.scopeCenterY
        radius: Math.min(width, height) * 0.8
        strokeWidth: 2
        gapLength: parent.width * (1 / 32)
        gapAngle: 20
        range: 80
        tickOffset: -ownship.heading
    }

    // The 1v1 scenario: ownship under player control and one hostile fighter
    // boring in from the north. Kinetic and maneuver are direct rates (px/s
    // and deg/s); the other stats keep briardart's fighter ratings until
    // systems read them.
    Entity {
        id: ownship
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Ownship
        kinetic: 120
        maneuver: 120
        durable: 5
        compute: 6
        sensor: 7
        stealth: 5
    }

    Entity {
        id: bandit
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Hostile
        posY: -400
        heading: 180
        kinetic: 100
        maneuver: 90
        durable: 5
        compute: 6
        sensor: 7
        stealth: 5
    }

    readonly property list<Entity> entities: [ownship, bandit]

    Item {
        id: scene
        anchors.fill: parent
        focus: true // route the window's keys (WASD / arrows) here

        property bool padConnected: false

        // The input handlers only capture state into the pilot system; the
        // runner below folds it into the game once per frame.
        Keys.onPressed: event => {
            if (event.isAutoRepeat)
                return;
            pilot.held[event.key] = true;
            event.accepted = true;
        }
        Keys.onReleased: event => {
            if (event.isAutoRepeat)
                return;
            pilot.held[event.key] = false;
            event.accepted = true;
        }

        // Gamepad input via awen.gamepad; these fire regardless of focus. On wasm
        // the browser refreshes gamepad state once per frame, so poll at 16ms there.
        Gamepad.pollInterval: Qt.platform.os === "wasm" ? 16 : 8
        Gamepad.onConnected: deviceId => scene.padConnected = true
        Gamepad.onDisconnected: deviceId => scene.padConnected = false
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            if (axis === Gamepad.Axis.LeftX)
                pilot.padX = pilot.deaden(value);
            else if (axis === Gamepad.Axis.LeftY)
                pilot.padY = pilot.deaden(value);
        }
        Gamepad.onButtonPressed: (deviceId, button) => pilot.dpad[button] = true
        Gamepad.onButtonReleased: (deviceId, button) => pilot.dpad[button] = false

        // The game's systems, in run order: capture inputs into ownship's
        // commands, fly the bandit, then integrate every entity's pose.
        Systems {
            SystemPilot {
                id: pilot
                entity: ownship
            }
            SystemPursuit {
                entity: bandit
                target: ownship
            }
            SystemMovement {
                entities: root.entities
            }
        }

        // The world, drawn heading-up around ownship: shift ownship to the
        // origin, rotate the world against its heading, then pin it to the
        // scope centre. Symbols are children at world coordinates.
        Item {
            id: world
            transform: [
                Translate {
                    x: -ownship.posX
                    y: -ownship.posY
                },
                Rotation {
                    angle: -ownship.heading
                },
                Translate {
                    x: root.scopeCenterX
                    y: root.scopeCenterY
                }
            ]

            Repeater {
                model: root.entities
                delegate: EntitySymbol {
                    required property Entity modelData
                    entity: modelData
                    worldRotation: -ownship.heading
                    showLabel: modelData.side !== Side.Kind.Ownship
                }
            }
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
            text: qsTr("W to thrust, A/D to turn — arrows, stick or d-pad too")
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
