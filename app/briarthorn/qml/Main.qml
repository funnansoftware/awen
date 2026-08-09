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
import "audio"
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

    // The duel actually under the player's hands: running, with no overlay over
    // it. The scene's focus, its key handlers, the wheel's ranging, the trails
    // and the top bar's own button all follow this one predicate rather than
    // each spelling the mode set out again.
    readonly property bool live: !root.inMenu && !root.paused && !root.ended && !settings.open

    // The shot the player is holding armed, if any. Every arming cue reads off
    // this one slot: the scope paints the envelope its round can reach and
    // brackets the return its seeker is holding, and the readout says what it
    // is waiting on. Null — the disarmed case — leaves all three off.
    readonly property AbilitySlot armed: game.ownship.armedAbility
    readonly property real armedReach: root.armed ? root.armed.reach : 0
    readonly property bool armedValid: root.armed !== null && root.armed.valid
    readonly property string lockedContact: root.armed && root.armed.lock ? root.armed.lock.callsign : ""

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
        // Builds the cue singleton now so its effects are loaded before the
        // first press asks for one — see Sfx.warm().
        Sfx.warm();
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

        // The top band's height, and through it every size drawn in the band: a
        // fraction of the smaller window side, as the corner instruments are.
        // The fraction puts it at 64 on the 1280x720 window it was drawn for.
        // Floored at a thumb's target, because the band is the settings
        // button's whole hit area, and capped so a tall display does not give a
        // status strip a tenth of the picture.
        readonly property real bandHeight: Math.max(44, Math.min(96, Math.min(root.width, root.height) * 0.089))

        anchors.fill: parent
        // The window's keys go here unless the settings page or one of the
        // overlay menus has them — each declares its own focus, and the
        // bindings trade it as those states flip.
        focus: root.live

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
            // A backstop only: the scene holds the keys in no other mode, and
            // the overlays are siblings, so nothing of theirs reaches here. It
            // guards on the same predicate as the focus above rather than a
            // near-copy, so anything inside the scene that ever takes focus
            // cannot open a mode this handler still answers in.
            if (!root.live)
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
            if (!event.isAutoRepeat && root.live)
                event.accepted = actions.keyReleased(event.key);
        }

        // Controller events ignore focus entirely, so handing the page the
        // keyboard is not enough — the pad route is switched here instead.
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            root.device.moved(value);
            if (settings.open)
                settings.axisMoved(axis, value);
            else if (root.inMenu)
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
                negative: root.keymap.flight.throttle.key.negative
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

            enabled: root.live
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
        // ability clocks, fuel, poses, arena collision on the fresh poses,
        // weapons, countermeasures and the radar sweep, detection last so
        // tracks see the tick's outcome.
        // Every system runs in every mode and processes exactly the entities
        // carrying its aspect; the scenarios only shape the world and never
        // load systems of their own.
        Systems {
            // The settings page, the pause menu and a decided duel all stop
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
                obstacles: root.world.obstacles
            }

            SystemPersonality {
                entities: root.entities
            }

            SystemManeuver {
                entities: root.entities
            }

            SystemAvoidance {
                entities: root.entities
                obstacles: root.world.obstacles
            }

            SystemEngage {
                entities: root.entities
                obstacles: root.world.obstacles
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

            SystemCollision {
                world: root.world
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
                obstacles: root.world.obstacles
            }
        }

        // The full-width top band: persistent meta-game state (the credit
        // purse), the build version and the way into the settings page. It owns
        // the top strip; the scope sits below it.
        //
        // Its button pauses on the way in rather than opening over a running
        // duel: the page stops the sim either way, so this is the difference
        // between coming back to a RESUME and being dropped into the fight
        // mid-frame — and it is the state the pause menu's own route into the
        // page arrives from. Dead while an overlay is up, so the page can never
        // re-enter itself.
        ViewTopBar {
            id: topBar

            visible: !root.inMenu
            enabled: root.live
            height: scene.bandHeight
            credits: game.credits
            version: "v" + BuildInfo.version
            onSettingsRequested: {
                root.openPause();
                root.openSettings();
            }

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
            obstacles: root.world.obstacles
            symbolSize: height * 0.04
            trailsRunning: root.live
            armedReach: root.armedReach
            armedValid: root.armedValid
            lockedContact: root.lockedContact

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

        // The arming readout, stacked under the missile warning in the same
        // top-centre alert channel: while a weapon is held armed, what it is
        // waiting on in words. It shares the channel rather than sitting by
        // the rack, because a touch player's rack is under their own thumb and
        // a desktop player's is in the far corner — the alert band is the one
        // place both are already looking. Rides below the warning where both
        // are up, so neither ever covers the other.
        ViewArming {
            id: armingAlert

            visible: !root.inMenu && armingAlert.active
            ownship: game.ownship
            // Never off the edge of a phone: the reason elides instead.
            maximumWidth: root.width - 32

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: threatAlert.visible ? threatAlert.bottom : topBar.bottom
                topMargin: 12
            }
        }

        // The ability rack, bottom-right: one square button per carried
        // ability, capped with the key or pad button that fires it and posting
        // the same ability record those bindings post — no second invocation
        // path. A thumb landing on one hands the HUD back to the touch
        // controls. Docked in the corner rather than centred: the scope's
        // centre column carries ownship, its pulse, the decoys it pops and the
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
            // The stick's whole travel is the lever: pushed past centre
            // throttles up, pulled back brakes.
            onValueYChanged: axisThrottle.invoke(valueY)
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
            obstacles: root.world.obstacles

            radiusFraction: 0.45
            symbolSize: height * 0.08
            // The envelope mirrors onto the overview with everything else the
            // minimap keeps; the lock bracket does not, because a mark drawn
            // this small has no room to stand one off.
            armedReach: root.armedReach
            armedValid: root.armedValid
            backgroundColor: Style.theme.windowBackground
            gutterClamp: true
            closedRings: true
            showNorth: true
            showInnerRing: false
            showTicks: false
            showRadarCone: true
            showOwnshipPulse: false
            showTrackLabels: false
            showTrackHealth: false
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
            obstacles: root.world.obstacles
            radiusFraction: 0.64
            verticalShift: 0.18
            horizontalShift: 0.25
            symbolSize: height * 0.04
            trailsRunning: root.inMenu && !settings.open

            anchors.fill: parent
        }
    }

    // Every overlay screen is a sibling of the scene rather than a child, for
    // the reason spelled out on the settings page below: a key one of them
    // declines must bubble to the window, not sideways into the game's handler.
    // They stack in declaration order over the scene, exactly as they did as its
    // last children.

    // The launch screen itself, transparent over the demo scope. It holds
    // the keys while up — its own handlers drive the cursor — and hands
    // them to the settings page when that stacks on top.
    ViewMenu {
        id: menu

        visible: root.inMenu
        focus: root.inMenu && !settings.open
        device: root.device
        onDuel: root.startDuel()
        onSettingsRequested: root.openSettings()
        onExitGame: Qt.quit()

        anchors.fill: parent
    }

    // The pause menu, over the frozen scope and HUD; the settings page
    // stacks on top of it and hands the keys back on close.
    ViewPause {
        id: pausePage

        visible: root.paused
        focus: root.paused && !settings.open
        device: root.device
        onResumed: root.resumeDuel()
        onRestarted: root.startDuel()
        onSettingsRequested: root.openSettings()
        onToMenu: root.startMenu()
        onExitGame: Qt.quit()

        anchors.fill: parent
    }

    // The duel's result, over the deciding frame.
    ViewEnd {
        id: endPage

        visible: root.ended
        // Yields to the settings page as the other two overlays do. Out of
        // reach today — the page stops the sim, so no duel can be decided
        // behind it — but a page left visible with the keyboard taken from it
        // under C++ would never get its focus binding back.
        focus: root.ended && !settings.open
        device: root.device
        mission: mission
        onFlyAgain: root.startDuel()
        onToMenu: root.startMenu()
        onExitGame: Qt.quit()

        anchors.fill: parent
    }

    // The settings page, a sibling of the scene rather than a child: it paints
    // over the whole HUD, and a key it declines bubbles to the window instead of
    // falling sideways into the game's handler. An overlay's entries act inside
    // the very key handler that reads them — starting the duel, unpausing — so a
    // key that fell through to the scene would be read by the game the overlay
    // had already switched to, one dispatch too late for the scene's mode guards
    // to refuse it. Focus follows open on both sides declaratively — an
    // imperative hand-off leaves the scene unfocused and the game permanently
    // deaf the moment one exit path forgets to hand it back.
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
        // The demo plays an open sky: the duel's arena leaves with the duel.
        root.world.obstacles = [];
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
    // pair on the game range step. Clears the pause the way startMenu() does,
    // so a restart taken from the pause page leaves the fresh duel running
    // rather than frozen behind the overlay it was ordered from.
    function startDuel() {
        root.paused = false;
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
        root.world.obstacles = scenario.obstacles;
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
