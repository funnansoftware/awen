// Ids from this file reach into the ability rack's delegate below; bound
// component behaviour is what makes those resolve statically.
pragma ComponentBehavior: Bound

import QtQml.Models
import QtQuick
import awen.buildinfo
import awen.command
import awen.entity
import awen.gamepad
import awen.input
import "commands"
import "input"
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

    // The world's roster is everything the simulation integrates: the
    // player's craft and the scenario's entities are enrolled at startup,
    // and the weapon systems spawn and reap missiles and decoys in it.
    readonly property World world: World {}
    readonly property list<Entity> entities: root.world.entities

    // The player's ability controls, loaded at startup; the settings page edits
    // this table and every ability binding re-pushes off it.
    readonly property Keymap keymap: Keymap {}

    width: 1280
    height: 720
    visible: true
    // On wasm, fill the web shell's container div exactly — frameless, because Qt
    // otherwise paints its own title bar inside the embedded view.
    visibility: Qt.platform.os === "wasm" ? Window.Maximized : Window.Windowed
    flags: Qt.platform.os === "wasm" ? Qt.FramelessWindowHint : Qt.Window
    title: qsTr("briarthorn")
    color: Style.theme.windowBackground

    // Focus loss swallows key and touch releases, so drop all held input with it.
    onActiveChanged: if (!active)
        root.dropInput()

    Component.onCompleted: {
        root.world.add(game.ownship);
        for (let i = 0; i < scenario.entities.length; ++i)
            root.world.add(scenario.entities[i]);
    }

    // The one display projection both scopes share: ranging in or out moves the
    // centre attack scope and the corner minimap together.
    RangeProjection {
        id: projection
        step: 2 // the 40 / 80 km picture
    }

    Item {
        id: scene

        // Read off the live device set rather than accumulated from the connect
        // edge: a controller plugged in before launch is opened before this item
        // ever attaches, so there is no edge left for it to catch.
        readonly property bool padConnected: Gamepad.devices.length > 0

        anchors.fill: parent
        focus: !settings.open // the window's keys go here unless the page has them

        // Gamepad input via awen.gamepad; these fire regardless of focus. On wasm
        // the browser refreshes gamepad state once per frame, so poll at 16ms there.
        Gamepad.pollInterval: Qt.platform.os === "wasm" ? 16 : 8

        // The input handlers only route events into the action map; only mapped
        // keys are consumed. The page key is handled ahead of the map: it has
        // no axis and no rest state, and the way out of the game must never be
        // rebound away.
        Keys.onPressed: event => {
            if (event.isAutoRepeat)
                return;
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                root.openSettings();
                event.accepted = true;
                return;
            }
            event.accepted = actions.keyPressed(event.key);
        }
        Keys.onReleased: event => {
            if (!event.isAutoRepeat)
                event.accepted = actions.keyReleased(event.key);
        }

        // Controller events ignore focus entirely, so handing the page the
        // keyboard is not enough — the pad route is switched here instead.
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            if (!settings.open)
                actions.axisMoved(axis, value);
        }
        Gamepad.onButtonPressed: (deviceId, button) => {
            if (settings.open)
                settings.padPressed(button);
            else if (button === Gamepad.Button.Start)
                root.openSettings();
            else
                actions.buttonPressed(button);
        }
        Gamepad.onButtonReleased: (deviceId, button) => {
            if (!settings.open)
                actions.buttonReleased(button);
        }

        // The input layer: keys, controller and (later) touch all fold into
        // these axes through the action bindings below.
        Axis {
            id: axisSteer
        }

        Axis {
            id: axisThrottle
            minimum: 0
        }

        // The scope's range control. A stepped axis, not a held one: each edge
        // moves the picture one step and the release back to rest moves
        // nothing, so a control held down never runs the range away.
        Axis {
            id: axisRange
            onValueChanged: {
                if (axisRange.value > 0.5)
                    projection.rangeIn();
                else if (axisRange.value < -0.5)
                    projection.rangeOut();
            }
        }

        Actions {
            id: actions

            // The flight controls, fixed: a two-way axis and an analogue stick
            // generalise from nothing an ability row carries. Their codes live
            // on the keymap so a capture can refuse one — the router fans every
            // event to every action, so an ability sharing W would thrust as
            // well as fire.
            ActionKey {
                control: axisSteer
                positive: root.keymap.flight.steer.key.positive
                negative: root.keymap.flight.steer.key.negative
            }

            ActionKey {
                control: axisThrottle
                positive: root.keymap.flight.throttle.key.positive
            }

            ActionButton {
                control: axisSteer
                positive: root.keymap.flight.steer.pad.positive
                negative: root.keymap.flight.steer.pad.negative
            }

            ActionButton {
                control: axisThrottle
                positive: root.keymap.flight.throttle.pad.positive
            }

            ActionButton {
                control: axisRange
                positive: root.keymap.range.pad.positive
                negative: root.keymap.range.pad.negative
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

        // Ability input is data: one axis, one key binding, one pad binding and
        // one command per ability the flown craft actually carries, off the
        // loadout and through the keymap. Adding an ability touches nothing in
        // this file.
        Instantiator {
            model: game.ownship.abilities

            delegate: AbilityInput {
                required property AbilitySlot modelData

                def: modelData.def
                keymap: root.keymap
                queue: bus
            }

            // The delegate arrives typed as a bare QObject, so it is cast back
            // to what it is before its two bindings are read.
            onObjectAdded: (index, object) => {
                const input = object as AbilityInput;
                actions.actions.push(input.keys);
                actions.actions.push(input.pad);
            }
            // Pruned by the object handed in, never by rescanning the rack: a
            // delegate being removed is already on its way out.
            onObjectRemoved: (index, object) => {
                const input = object as AbilityInput;
                const kept = [];
                for (let i = 0; i < actions.actions.length; ++i) {
                    const action = actions.actions[i];
                    if (action !== input.keys && action !== input.pad)
                        kept.push(action);
                }
                actions.actions = kept;
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

        // The touch rack's invocations. One emitter serves every button — the
        // ability rides as a per-post override, so the rack needs no command
        // object of its own and posts exactly the record a key press posts.
        CommandAbility {
            id: touched
            queue: bus
        }

        // The mouse's range control: wheel up ranges in, wheel down out. It
        // steps per notch of 120 units — a trackpad sends smaller ones, so they
        // bank up into a step, and a reversal drops what was banked rather than
        // spending it against the new direction.
        WheelHandler {
            id: wheel

            property real banked: 0

            enabled: !settings.open
            onWheel: event => {
                if (wheel.banked * event.angleDelta.y < 0)
                    wheel.banked = 0;
                wheel.banked += event.angleDelta.y;
                while (wheel.banked >= 120) {
                    wheel.banked -= 120;
                    projection.rangeIn();
                }
                while (wheel.banked <= -120) {
                    wheel.banked += 120;
                    projection.rangeOut();
                }
            }
        }

        // Run order is the lifetimes and the data flow: publish the batch,
        // consume player intent into the game store, run the scenario's own
        // systems (AI steering and trigger discipline), age ability clocks,
        // integrate poses, then resolve weapons, countermeasures and the
        // radar sweep — detection last, so tracks see the tick's outcome.
        Systems {
            // The page stops the duel rather than letting it run on behind the
            // player. dropInput() posts the zeroed axes before this flips, and
            // nothing clears the queue, so they publish on resume.
            running: !settings.open

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
                world: root.world
            }

            SystemAbility {
                world: root.world
            }

            SystemMovement {
                entities: root.entities
            }

            SystemFuel {
                entity: game.ownship
            }

            SystemWeapon {
                id: weapons
                world: root.world
                invulnerable: [game.ownship]
            }

            SystemCountermeasure {
                world: root.world
            }

            SystemDetection {
                id: detection
                observer: game.ownship
                entities: root.entities
            }
        }

        // The full-width top band: persistent meta-game state (the credit purse)
        // and the build version. It owns the top strip; the scope sits below it.
        ViewTopBar {
            id: topBar

            credits: game.credits
            version: "v" + BuildInfo.version

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }

        // The attack scope: the game's main centre display. Rings, ownship's
        // radar cone, the heading-up track picture and ownship pinned at the
        // dropped centre — all composed by ViewSituation on the shared
        // projection. It fills the area BELOW the bar, with a gap so a track
        // plotting along the top edge clears the bar, and clips so nothing ever
        // renders up into it.
        ViewSituationAttack {
            clip: true
            projection: projection
            observer: game.ownship
            tracks: detection.tracks
            entities: root.entities
            detonations: weapons.detonations
            symbolSize: height * 0.04

            anchors {
                left: parent.left
                right: parent.right
                top: topBar.bottom
                topMargin: 16
                bottom: parent.bottom
            }
        }

        // Ownship condition readout, top-left: a round dual-arc gauge (hull +
        // fuel) sized to the minimap opposite, so the two round instruments read
        // as a matched, compact pair. Dropped below the top band.
        ViewStatus {
            width: Math.min(root.width, root.height) * 0.22
            height: width
            ownship: game.ownship

            anchors {
                left: parent.left
                leftMargin: 16
                top: topBar.bottom
                topMargin: 12
            }
        }

        // The control hints: the fixed flight keys, then one chip per ability
        // the craft carries, captioned with whatever it is bound to right now.
        // A touch device has no controls to caption and flies from the two
        // corner controls instead, so the line gives way to the rack there.
        ViewHints {
            visible: !TouchScreen.available
            keymap: root.keymap
            loadout: game.ownship.abilities

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 24
            }
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
            visible: TouchScreen.available && !settings.open
            onValueXChanged: axisSteer.invoke(valueX)
            // The stick has no reverse, so a downward pull must not subtract
            // from a throttle another source (keys, pad) is holding up.
            onValueYChanged: axisThrottle.invoke(Math.max(0, valueY))
            onActiveChanged: if (!active) {
                axisSteer.invoke(0);
                axisThrottle.invoke(0);
            }

            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 24
            }
        }

        // The ability rack, bottom-right: one round button per carried ability
        // on a quarter arc swept between the two edges, under the right thumb
        // as the stick is under the left. It posts the same ability record the
        // key and pad bindings post, so touch adds no second invocation path.
        TouchAbilities {
            radius: Math.min(root.width, root.height) * 0.28
            visible: TouchScreen.available && !settings.open
            loadout: game.ownship.abilities
            onInvoked: ability => touched.post({ ability: ability })
            // The range pair at the rack's pivot drives the projection direct:
            // the scope is a display, so ranging it never goes near the bus.
            onRangedIn: projection.rangeIn()
            onRangedOut: projection.rangeOut()

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: 24
            }
        }

        // The corner minimap, top-right — mirroring the round condition gauge in
        // the opposite corner. The same situation display, stripped to a clean
        // overview. It shares the attack scope's projection, so it ranges with
        // it. Off-scale contacts clamp into the gutter and an opaque disc backs
        // the picture, masking anything outside the view from rendering over
        // the scope beneath it.
        ViewSituation {
            id: minimap

            width: Math.min(root.width, root.height) * 0.22
            height: width

            projection: projection
            observer: game.ownship
            tracks: detection.tracks

            radiusFraction: 0.45
            symbolSize: height * 0.08
            backgroundColor: Style.theme.windowBackground
            gutterClamp: true
            closedRings: true
            showNorth: true
            showInnerRing: false
            showTicks: false
            showRadarCone: true
            showOwnshipPulse: false
            showTrackLabels: false
            showEngagements: false

            anchors {
                right: parent.right
                rightMargin: 16
                top: topBar.bottom
                topMargin: 12
            }
        }

        // The controller lamp, tucked under the minimap on the right; lights up
        // when a controller is connected, so the gamepad path is visible.
        Text {
            text: qsTr("controller connected")
            color: "#66bfff"
            font.pixelSize: 13
            visible: scene.padConnected

            anchors {
                right: parent.right
                rightMargin: 16
                top: minimap.bottom
                topMargin: 6
            }
        }
    }

    // The controls page, a sibling of the scene rather than a child: it paints
    // over the whole HUD, and a key it declines bubbles to the window instead of
    // falling sideways into the game's handler. Focus follows open on both sides
    // declaratively — an imperative hand-off leaves the scene unfocused and the
    // game permanently deaf the moment one exit path forgets to hand it back.
    ViewSettings {
        id: settings

        anchors.fill: parent
        keymap: root.keymap
        loadout: game.ownship.abilities
        onClosed: root.closeSettings()
    }

    // Returns every input source to rest: the action bindings, and the stick's
    // own axis slots, which it contributes under the axis itself and so the
    // router cannot reach.
    function dropInput() {
        actions.reset();
        axisSteer.invoke(0);
        axisThrottle.invoke(0);
    }

    // Held input is released while the bus is still running, so the zeroed steer
    // and throttle post before the simulation stops. Both verbs coalesce, so
    // they publish on resume and the ship never carries its pre-pause command
    // out of the page — which is also why nothing clears the queue.
    function openSettings() {
        root.dropInput();
        settings.open = true;
    }

    function closeSettings() {
        settings.open = false;
        root.dropInput();
    }
}
