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

    // What the player is flying with right now. Every input route below reports
    // into it, and the HUD swaps its controls and their captions off it: the
    // thumb rack and stick, key caps, or the pad's own button glyphs.
    readonly property ActiveDevice device: ActiveDevice {}

    // The launch screen versus the duel: while up, the menu scenario plays
    // its hands-off demo behind the overlay, the HUD stands down and every
    // input route feeds the menu cursor instead of the game.
    property bool inMenu: true

    // The pause menu, duel only: the sim freezes behind it and the input
    // routes feed its cursor, exactly as the launch screen's.
    property bool paused: false

    // Whether the duel has been decided: the sim freezes on the deciding
    // frame and the end screen takes the input until the player moves on.
    readonly property bool ended: !root.inMenu && mission.status !== SystemMission.Status.Ongoing

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

    // Only ownship enrolls at startup: the menu demo spawns its own waves,
    // and the duel's entities join when startDuel() enrolls them.
    Component.onCompleted: {
        root.world.add(game.ownship);
        root.startMenu();
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

        // The one side both round corner instruments (condition gauge, minimap)
        // draw at, floored where the readouts inside them would shrink
        // illegible — a single property, so the pair stays a pair structurally.
        readonly property real instrumentSide: Math.max(110, Math.min(root.width, root.height) * 0.22)

        anchors.fill: parent
        // The window's keys go here unless the controls page or one of the
        // overlay menus has them — each declares its own focus, and the
        // bindings trade it as those states flip.
        focus: !settings.open && !root.inMenu && !root.paused && !root.ended

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
            // Keys a focused overlay menu declined bubble up here; they have
            // no game meaning while one is up.
            if (root.inMenu || root.paused || root.ended)
                return;
            // Any key at all hands the HUD back to the keyboard, bound or not:
            // a player reaching for keys wants the key caps, not the pad's.
            root.device.kind = ActiveDevice.Keyboard;
            if (event.key === Qt.Key_Escape || event.key === Qt.Key_Back) {
                root.openPause();
                event.accepted = true;
                return;
            }
            event.accepted = actions.keyPressed(event.key);
        }
        Keys.onReleased: event => {
            if (!event.isAutoRepeat && !root.inMenu && !root.paused && !root.ended)
                event.accepted = actions.keyReleased(event.key);
        }

        // Controller events ignore focus entirely, so handing the page the
        // keyboard is not enough — the pad route is switched here instead.
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            root.device.moved(value);
            if (settings.open)
                return;
            if (root.inMenu)
                menu.axisMoved(axis, value);
            else if (root.ended)
                endPage.axisMoved(axis, value);
            else if (root.paused)
                pausePage.axisMoved(axis, value);
            else
                actions.axisMoved(axis, value);
        }
        Gamepad.onButtonPressed: (deviceId, button) => {
            root.device.kind = ActiveDevice.Gamepad;
            if (settings.open)
                settings.padPressed(button);
            else if (root.inMenu)
                menu.padPressed(button);
            else if (root.ended)
                endPage.padPressed(button);
            else if (root.paused)
                pausePage.padPressed(button);
            else if (button === Gamepad.Button.Start)
                root.openPause();
            else
                actions.buttonPressed(button);
        }
        Gamepad.onButtonReleased: (deviceId, button) => {
            if (!settings.open && !root.inMenu && !root.paused && !root.ended)
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

        // The scope's range control, the one object every ranging source —
        // d-pad edge, wheel notch, touch tap — converges on. A stepped axis,
        // not a held one: each step out of rest moves the picture once and the
        // release back moves nothing, so a control held down never runs the
        // range away.
        Axis {
            id: axisRange
            onStepped: direction => {
                if (direction > 0)
                    projection.rangeIn();
                else
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

        // The mouse's range control, stepping the shared axis: wheel up ranges
        // in, wheel down out. It steps per notch of 120 units — a trackpad
        // sends smaller ones, so they bank up into a step, and a reversal
        // drops what was banked rather than spending it against the new
        // direction.
        WheelHandler {
            id: wheel

            property real banked: 0

            enabled: !settings.open && !root.inMenu && !root.paused && !root.ended
            onWheel: event => {
                // The mouse belongs to the desktop set, so a scroll counts as
                // keyboard play for the HUD's captions.
                root.device.kind = ActiveDevice.Keyboard;
                if (wheel.banked * event.angleDelta.y < 0)
                    wheel.banked = 0;
                wheel.banked += event.angleDelta.y;
                while (wheel.banked >= 120) {
                    wheel.banked -= 120;
                    axisRange.step(1);
                }
                while (wheel.banked <= -120) {
                    wheel.banked += 120;
                    axisRange.step(-1);
                }
            }
        }

        // Run order is the lifetimes and the data flow: publish the batch,
        // consume player intent into the game store, let the scenarios set
        // conditions, judge the duel, then run the one set of shared systems
        // — threat marks first so minds and reflexes read fresh inbounds,
        // personalities pick their stances, behaviour by entity aspect,
        // ability clocks, fuel, poses, weapons, countermeasures and the
        // radar sweep, detection last so tracks see the tick's outcome.
        // Every system runs in every mode and processes exactly the entities
        // carrying its aspect; the scenarios only shape the world and never
        // load systems of their own.
        Systems {
            // The controls page, the pause menu and a decided duel all stop
            // the sim rather than letting it run on behind the player.
            // dropInput() posts the zeroed axes before these flip, and
            // nothing clears the queue, so they publish on resume.
            running: !settings.open && !root.paused && !root.ended

            CommandQueue {
                id: bus
            }

            StoreGame {
                id: game
                queue: bus
            }

            ScenarioMenu {
                id: demo
                enabled: root.inMenu
                ownship: game.ownship
                world: root.world
            }

            ScenarioDuel {
                id: scenario
                enabled: !root.inMenu
                ownship: game.ownship
            }

            // The duel's judge, always on: in menu mode both hulls it reads
            // sit topped or out of the fight, so the latch never trips.
            SystemMission {
                id: mission
                player: game.ownship
                target: scenario.bandit
            }

            SystemThreat {
                entities: root.entities
            }

            SystemPersonality {
                entities: root.entities
            }

            SystemManeuver {
                entities: root.entities
            }

            SystemEngage {
                entities: root.entities
            }

            SystemAbility {
                world: root.world
            }

            SystemFuel {
                entities: root.entities
            }

            SystemMovement {
                entities: root.entities
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

            visible: !root.inMenu
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
            visible: !root.inMenu
            clip: true
            projection: projection
            observer: game.ownship
            tracks: detection.tracks
            entities: root.entities
            detonations: weapons.detonations
            symbolSize: height * 0.04
            trailsRunning: !settings.open && !root.inMenu && !root.paused && !root.ended

            anchors {
                left: parent.left
                right: parent.right
                top: topBar.bottom
                topMargin: 16
                bottom: parent.bottom
            }
        }

        // Ownship condition readout, top-left: a round dual-arc gauge (hull +
        // fuel) on the shared instrument side, so it and the minimap opposite
        // read as a matched, compact pair. Dropped below the top band.
        ViewStatus {
            visible: !root.inMenu
            width: scene.instrumentSide
            height: width
            ownship: game.ownship

            anchors {
                left: parent.left
                leftMargin: 16
                top: topBar.bottom
                topMargin: 12
            }
        }

        // The missile warning, top-centre under the band: flashes the moment
        // a homing round is marked inbound on ownship, with its bearing and
        // closing range — the reaction window the scope alone buries in a
        // small mark.
        ViewThreat {
            id: threatAlert

            visible: !root.inMenu && threatAlert.active
            ownship: game.ownship

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: topBar.bottom
                topMargin: 12
            }
        }

        // The ability rack, bottom-right: one square button per carried
        // ability, capped with the key or pad button that fires it and posting
        // the same ability record those bindings post — no second invocation
        // path. A thumb landing on one hands the HUD back to the touch
        // controls. Docked in the corner rather than centred: the scope's
        // centre column carries ownship, its pulse, the decoys astern and the
        // pursuer's sector, and the rack is captions and clocks, so it is what
        // gives way.
        ViewAbilities {
            id: abilities

            // How far ownship's acquisition pulse draws past the scope centre
            // (ViewSituation's pulse ring); the rack reaches in from its margin
            // no further than the pulse's edge.
            readonly property real pulseReach: 48

            visible: !root.device.touch && !settings.open && !root.inMenu
            // Smaller than a touch target: nothing here is ever pressed by a
            // thumb, because a touchscreen press hands the HUD to the arc rack
            // instead. Sized so the rack clears ownship's own bearing line as
            // well as its column on any window taller than about 720.
            buttonSize: Math.max(44, Math.min(root.width, root.height) * 0.07)
            // A craft carrying six abilities shrinks its buttons rather than
            // growing across the scope centre.
            maximumWidth: root.width / 2 - abilities.pulseReach - abilities.anchors.margins
            keymap: root.keymap
            loadout: game.ownship.abilities
            device: root.device
            onInvoked: ability => touched.post({ ability: ability })
            onTouched: root.device.kind = ActiveDevice.Touch

            anchors {
                right: parent.right
                bottom: parent.bottom
                margins: 20
            }
        }

        // The flight hints, along the bottom edge beside the rack: the fixed
        // controls the craft flies on, phrased for the device in the player's
        // hands. Centred on the window rather than hung off the rack — it
        // captions the flight controls, not the abilities — and seated at the
        // very bottom, which is what keeps it off the ownship symbol on a tall
        // display. A touch device flies from the two corner controls instead
        // and has nothing to caption, so the line gives way with the rack.
        ViewHints {
            visible: abilities.visible
            device: root.device
            // Centred, but never under the rack: capped so the line's right
            // edge stays clear of abilities' left and elides on a window too
            // narrow to hold both.
            width: Math.max(0, Math.min(implicitWidth, 2 * (abilities.x - 16) - root.width))

            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 20
            }
        }

        // The on-screen stick: another source folding into the same axes — its x
        // steers, forward throttles. It contributes under the axis key, summed
        // with keys and the pad, so release must zero it back out.
        Joystick {
            id: stick

            implicitWidth: root.width * 0.125
            // Touch play only: the on-screen stick shows on phones, tablets and
            // touch browsers, and gives way the moment keys or a gamepad take
            // over — including on a laptop that has both.
            visible: TouchScreen.available && root.device.touch && !settings.open && !root.inMenu
            onValueXChanged: axisSteer.invoke(valueX)
            // The stick has no reverse, so a downward pull must not subtract
            // from a throttle another source (keys, pad) is holding up.
            onValueYChanged: axisThrottle.invoke(Math.max(0, valueY))
            onActiveChanged: {
                if (stick.active)
                    root.device.kind = ActiveDevice.Touch;
                else {
                    axisSteer.invoke(0);
                    axisThrottle.invoke(0);
                }
            }

            anchors {
                left: parent.left
                bottom: parent.bottom
                margins: 24
            }
        }

        // The touch ability rack, bottom-right: one square button per carried
        // ability on a quarter arc swept between the two edges, under the right
        // thumb as the stick is under the left. It posts the same ability record
        // the key and pad bindings post, so touch adds no second invocation path.
        TouchAbilities {
            radius: Math.min(root.width, root.height) * 0.28
            visible: TouchScreen.available && root.device.touch && !settings.open && !root.inMenu
            loadout: game.ownship.abilities
            onInvoked: ability => touched.post({ ability: ability })
            // The range pair at the rack's pivot steps the shared range axis,
            // same as the wheel and the d-pad: the scope is a display, so
            // ranging it never goes near the bus.
            onRangedIn: axisRange.step(1)
            onRangedOut: axisRange.step(-1)

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

            visible: !root.inMenu
            width: scene.instrumentSide
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
            showTrails: false

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
            color: Style.theme.textLabel
            font { pixelSize: 12; family: Style.monospace }
            visible: scene.padConnected && !root.inMenu

            anchors {
                right: parent.right
                rightMargin: 16
                top: minimap.bottom
                topMargin: 6
            }
        }

        // The launch screen's backdrop: the same live situation display, its
        // picture pushed right and down (briardart's menu-demo geometry) so
        // the demo dogfight plays clear of the title band and the action rail.
        ViewSituation {
            visible: root.inMenu
            projection: projection
            observer: game.ownship
            tracks: detection.tracks
            entities: root.entities
            detonations: weapons.detonations
            radiusFraction: 0.64
            verticalShift: 0.18
            horizontalShift: 0.25
            symbolSize: height * 0.04
            trailsRunning: root.inMenu && !settings.open

            anchors.fill: parent
        }

        // The launch screen itself, transparent over the demo scope. It holds
        // the keys while up — its own handlers drive the cursor — and hands
        // them to the controls page when that stacks on top.
        ViewMenu {
            id: menu

            visible: root.inMenu
            focus: root.inMenu && !settings.open
            device: root.device
            onDuel: root.startDuel()
            onControls: root.openSettings()
            onExitGame: Qt.quit()

            anchors.fill: parent
        }

        // The pause menu, over the frozen scope and HUD; the controls page
        // stacks on top of it and hands the keys back on close.
        ViewPause {
            id: pausePage

            visible: root.paused
            focus: root.paused && !settings.open
            device: root.device
            onResumed: root.resumeDuel()
            onControls: root.openSettings()
            onToMenu: root.startMenu()
            onExitGame: Qt.quit()

            anchors.fill: parent
        }

        // The duel's result, over the deciding frame.
        ViewEnd {
            id: endPage

            visible: root.ended
            focus: root.ended
            device: root.device
            mission: mission
            onFlyAgain: root.startDuel()
            onToMenu: root.startMenu()
            onExitGame: Qt.quit()

            anchors.fill: parent
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
        device: root.device
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

    // The launch screen: the demo scenario populates the world itself, one
    // range step out from the tightest so the temperaments' fighting
    // envelopes stay on the picture. Arriving from a paused or decided duel,
    // the demo's own restart sweeps the fight's leavings and reseats ownship
    // for the show.
    function startMenu() {
        root.dropInput();
        root.paused = false;
        demo.restart();
        projection.step = 1;
        root.inMenu = true;
    }

    // Escape or Start mid-duel: freeze the sim behind the pause menu. Held
    // input is dropped while the bus still runs, exactly as the page does.
    function openPause() {
        root.dropInput();
        root.paused = true;
    }

    function resumeDuel() {
        root.paused = false;
        root.dropInput();
    }

    // New game: rebuild both craft factory-fresh, sweep the whole world —
    // the demo's leavings and the spent craft alike — and enroll the new
    // pair on the game range step.
    function startDuel() {
        demo.reset();
        game.reset();
        scenario.reset();
        mission.reset();
        const roster = root.world.entities.slice();
        for (let i = 0; i < roster.length; ++i)
            root.world.despawn(roster[i]);
        root.world.add(game.ownship);
        for (let i = 0; i < scenario.entities.length; ++i)
            root.world.add(scenario.entities[i]);
        projection.step = 2;
        root.inMenu = false;
        root.dropInput();
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
