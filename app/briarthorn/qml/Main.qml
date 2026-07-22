import QtQuick
import awen.entity
import awen.gamepad
import awen.shapes
import "model"
import "systems"
import "themes"
import "ui"

// The briarthorn 1v1 duel, pure QML: ownship pinned to the scope centre and
// flown with WASD / arrows or a gamepad, versus one pursuing hostile
// fighter. The scope is a radar picture — ownship's detection system builds
// tracks (azimuth and range in the observer's frame) and the view plots
// those, heading-up, through the range projection.
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
    // sector gets the space. The view pins ownship here.
    readonly property real scopeCenterX: width / 2
    readonly property real scopeCenterY: height * 0.875

    // How world metres project onto the scope: the outer ring's edge sits
    // 0.8 shortSide from the centre and spans the projection's range.
    readonly property real pxPerMeter: projection.pixelsPerMeter(Math.min(width, height) * 0.8)

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
        tickOffset: -ownship.heading
    }

    // The 1v1 scenario: ownship under player control and one hostile fighter
    // boring in from the north, spawned just past sensor range so it opens
    // as an Unknown contact. Stats are direct quantities — kinetic m/s,
    // maneuver deg/s, sensor detection range in metres.
    Entity {
        id: ownship
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Ownship
        radarFov: 120
        kinetic: 500
        maneuver: 12
        durable: 5
        compute: 6
        sensor: 60000
        stealth: 5
    }

    Entity {
        id: bandit
        callsign: "BANDIT 1"
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Hostile
        posY: -65000
        heading: 180
        radarFov: 120
        kinetic: 450
        maneuver: 9
        durable: 5
        compute: 6
        sensor: 60000
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
        // commands, fly the bandit, integrate every entity's pose, then
        // sweep ownship's radar into its track picture.
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
            SystemDetection {
                id: detection
                observer: ownship
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
            angleSpan: ownship.radarFov
            radius: ownship.sensor * root.pxPerMeter
            fillColor: Style.theme.gaugeTrack
        }

        // The track picture: every contact plotted at its azimuth and range
        // in ownship's heading-up frame.
        ViewTracks {
            anchors.fill: parent
            centerX: root.scopeCenterX
            centerY: root.scopeCenterY
            pxPerMeter: root.pxPerMeter
            observer: ownship
            tracks: detection.tracks
        }

        // Ownship, pinned at the scope centre, nose up by construction.
        Symbol {
            x: root.scopeCenterX - width / 2
            y: root.scopeCenterY - height / 2
            classification: ownship.classification
            side: ownship.side
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
