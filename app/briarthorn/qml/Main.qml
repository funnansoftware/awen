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

    // Which screen the shell is showing, and so which one holds the input.
    // One value, because these screens exclude each other: the pairs a set of
    // flags admitted — a pause menu over the launch screen, a duel started
    // with the settings page still up — are not states the game has any
    // meaning for, and every question below is asked of this rather than of a
    // combination each site spells out for itself.
    property int mode: Mode.Kind.Menu

    // Where the settings page was opened from, and so where it returns to and
    // what stays drawn behind it. openSettings() is its only writer, so the
    // page can never be standing over a screen it cannot go back to.
    property int settingsFrom: Mode.Kind.Menu

    // The screen on the stage. The settings page is a mode as far as the
    // input is concerned — it holds the keys and stops the sim — but a layer
    // as far as the picture is concerned: it is opened over something, and
    // what it was opened over goes on showing behind it.
    readonly property int stage: root.mode === Mode.Kind.Settings ? root.settingsFrom : root.mode

    // The duel actually under the player's hands: running, with no overlay over
    // it. The scene's focus, its key handlers, the wheel's ranging, the trails
    // and the top bar's own button all follow this one predicate.
    readonly property bool live: root.mode === Mode.Kind.Duel

    // Whether the duel is the session on the stage, whatever screen is over
    // it. The whole HUD, both scopes and the duel scenario follow this — a
    // paused or decided duel still draws its instruments, and the launch
    // screen's demo is what they give way to.
    readonly property bool inDuel: root.stage !== Mode.Kind.Menu

    // Whether the simulation integrates: no screen is up over the world, so
    // either the duel is being flown or the launch screen's demo is playing
    // behind it. The settings page, the pause menu and a decided duel all
    // stop the sim rather than letting it run on behind the player.
    readonly property bool running: root.mode === Mode.Kind.Menu || root.mode === Mode.Kind.Duel

    // Whether the hand controls are drawn: the thumb stick and the ability
    // racks, which the opaque settings page replaces rather than covers.
    readonly property bool racks: root.inDuel && root.mode !== Mode.Kind.Settings

    // Whether the duel's judge has latched an outcome. The end screen is a
    // mode like any other, so it is entered by a transition off this rather
    // than bound to it — see judge().
    readonly property bool decided: mission.status !== SystemMission.Status.Ongoing

    // The shot the player is holding armed, if any. Every arming cue reads off
    // this one slot: the scope paints the envelope its round can reach and
    // the readout says what it is waiting on. Null — the disarmed case —
    // leaves both off.
    readonly property AbilitySlot armed: game.ownship.armedAbility
    readonly property real armedReach: root.armed ? root.armed.reach : 0
    readonly property bool armedValid: root.armed !== null && root.armed.valid

    // The pilot's designated contact, straight off the flown craft, and —
    // where the survey validates it — the contact a guided launch would take
    // right now. The scope's cursor stands on the first and turns its latched
    // colour on the second; under designation the two can only ever name the
    // same mark.
    readonly property string selectedContact: game.ownship.targetContact
    readonly property string shootableContact: {
        for (let i = 0; i < game.ownship.abilities.length; ++i) {
            const slot = game.ownship.abilities[i];
            if (slot.guided && slot.lock !== null)
                return slot.lock.callsign;
        }
        return "";
    }

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

    // Both edges into the end screen are watched, not just the latch's: a duel
    // entered with an outcome already latched has to arrive at its result
    // rather than run on undecided, and a transition that forgets to rearm the
    // judge is exactly the mistake a bound `ended` used to make impossible.
    onDecidedChanged: root.judge()
    onLiveChanged: root.judge()

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
            if (event.isAutoRepeat || !root.live)
                return;
            event.accepted = actions.keyReleased(event.key);
            // Tab and Backtab are one physical key wearing the shift state of
            // the moment, so a press can come down as one and its release
            // come up as the other — release both, or the cycle key jams a
            // held contribution it can never clear.
            if (event.key === Qt.Key_Tab)
                actions.keyReleased(Qt.Key_Backtab);
            else if (event.key === Qt.Key_Backtab)
                actions.keyReleased(Qt.Key_Tab);
        }

        // Controller events ignore focus entirely, so handing the page the
        // keyboard is not enough — the pad route is switched on the mode here
        // instead.
        //
        // The window's own activation is tested first, and by all three, for
        // the same reason: the source only lengthens its poll interval when the
        // application deactivates, and SDL suppresses nothing for a process
        // that opened no window of its own, so the events keep arriving from
        // behind another window. Without this a pad knocked in the player's lap
        // flies the craft and fires its rack through a game nobody is looking
        // at — and answers the launch screen, where a press lands on whatever
        // the cursor is resting on, up to and including EXIT GAME.
        Gamepad.onAxisChanged: (deviceId, axis, value) => {
            if (!root.active)
                return;
            root.device.moved(value);
            // The flight axes hear the stick in every mode, not just the duel's.
            // A stick states a level and states it only when it moves, so the
            // one way to know where it is on the way back into the fight is to
            // have gone on listening while the overlay had the input. Their
            // fold is frozen off the duel (see axisSteer below), so listening
            // drives nothing — it only keeps the record honest.
            actions.axisMoved(axis, value);
            switch (root.mode) {
            case Mode.Kind.Settings:
                settings.axisMoved(axis, value);
                break;
            case Mode.Kind.Menu:
                menu.axisMoved(axis, value);
                break;
            case Mode.Kind.End:
                endPage.axisMoved(axis, value);
                break;
            case Mode.Kind.Pause:
                pausePage.axisMoved(axis, value);
                break;
            }
        }
        Gamepad.onButtonPressed: (deviceId, button) => {
            if (!root.active)
                return;
            root.device.kind = ActiveDevice.Gamepad;
            switch (root.mode) {
            case Mode.Kind.Settings:
                settings.padPressed(button);
                break;
            case Mode.Kind.Menu:
                menu.padPressed(button);
                break;
            case Mode.Kind.End:
                endPage.padPressed(button);
                break;
            case Mode.Kind.Pause:
                pausePage.padPressed(button);
                break;
            case Mode.Kind.Duel:
                if (button === Gamepad.Button.Start)
                    root.openPause();
                else
                    actions.buttonPressed(button);
                break;
            }
        }
        Gamepad.onButtonReleased: (deviceId, button) => {
            if (root.active && root.live)
                actions.buttonReleased(button);
        }

        // The input layer: keys, controller and (later) touch all fold into
        // these axes through the action bindings below.
        //
        // Both are frozen off the duel rather than silenced: their sources go
        // on recording while an overlay holds the input — which is what lets a
        // stick be re-read on the way back — and the fold catches up with the
        // controls in one step on re-enable. Frozen rather than merely
        // ignored because the launch screen's demo is a running simulation
        // driving the very craft these command, and a stick nudged while
        // reading a menu must not fly it.
        Axis {
            id: axisSteer
            enabled: root.live
        }

        Axis {
            id: axisThrottle
            enabled: root.live
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

        // The designation cycle: each step walks the selectable picture to the
        // next contact. Frozen off the duel like the flight axes — cycling
        // changes what a launch does, and a menu's Tab must never re-aim the
        // craft behind it.
        Axis {
            id: axisTarget
            enabled: root.live
            onStepped: direction => root.cycleTarget(direction)
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

            ActionKey {
                control: axisTarget
                positive: root.keymap.target.key.positive
                negative: root.keymap.target.key.negative
            }

            ActionButton {
                control: axisTarget
                positive: root.keymap.target.pad.positive
                negative: root.keymap.target.pad.negative
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

        // The designation's one path onto the bus: every selection source —
        // the cycle, a scope tap, a track list's row — posts through this.
        CommandTarget {
            id: designate
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
            // Only the two modes with nothing over the world integrate — see
            // root.running. resyncInput() posts the settled axes before this
            // flips, and nothing clears the queue, so they publish on resume.
            running: root.running

            CommandQueue {
                id: bus
            }

            StoreGame {
                id: game
                queue: bus
            }

            ScenarioMenu {
                id: demo
                enabled: !root.inDuel
                ownship: game.ownship
                world: root.world
            }

            ScenarioDuel {
                id: scenario
                enabled: root.inDuel
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

            SystemSentry {
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

            // Last, so every cue speaks for the tick that has just finished.
            // Disabled on the launch screen: the demo dogfight is scenery, and
            // scenery that fires missile warnings at a player reading a menu
            // is scenery that has misunderstood its job.
            SystemCue {
                enabled: root.inDuel
                ownship: game.ownship
            }
        }

        // The full-width top band: persistent meta-game state (the credit
        // purse), the build version and the way into the settings page. It owns
        // the top strip; the scope sits below it.
        //
        // Its button pauses on the way in rather than opening over a running
        // duel — openSettings() owns that, so the bar simply asks for the page
        // and cannot get the pair the wrong way round. Dead while an overlay is
        // up, so the page can never re-enter itself.
        ViewTopBar {
            id: topBar

            visible: root.inDuel
            enabled: root.live
            height: scene.bandHeight
            credits: game.credits
            version: "v" + BuildInfo.version
            onSettingsRequested: root.openSettings()

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
        }

        // The duel's HUD, one of two compositions behind the settings page's
        // layout choice. Loaders rather than a visibility flip: only one
        // object tree exists at a time, so the resting layout costs no
        // binding churn against the tick, and the choice only changes from
        // the settings page, where the sim is stopped and the construction
        // hitch is invisible. Views emit, and the routes onto the bus and the
        // device record stay here — swapping the picture must never grow a
        // second invocation path.
        Loader {
            active: !Style.hudTiled
            visible: root.inDuel
            anchors.fill: parent
            sourceComponent: ViewHudOverlay {
                ownship: game.ownship
                keymap: root.keymap
                device: root.device
                projection: projection
                tracks: detection.tracks
                entities: root.entities
                detonations: weapons.detonations
                obstacles: root.world.obstacles
                bandHeight: scene.bandHeight
                live: root.live
                racks: root.racks
                running: root.running
                padConnected: scene.padConnected
                armedReach: root.armedReach
                armedValid: root.armedValid
                selectedContact: root.selectedContact
                shootableContact: root.shootableContact
                onInvoked: ability => touched.post({ ability: ability })
                onTouched: root.device.kind = ActiveDevice.Touch
                // A tap toggles: tapping the selected contact stands it down.
                onContactChosen: contactId => designate.post({ contact: contactId === game.ownship.targetContact ? "" : contactId })
                onContactTouched: root.device.kind = ActiveDevice.Touch
            }
        }

        // The tiled composition, same contract, same routes.
        Loader {
            active: Style.hudTiled
            visible: root.inDuel
            anchors.fill: parent
            sourceComponent: ViewHudTiled {
                ownship: game.ownship
                keymap: root.keymap
                device: root.device
                projection: projection
                tracks: detection.tracks
                entities: root.entities
                detonations: weapons.detonations
                obstacles: root.world.obstacles
                bandHeight: scene.bandHeight
                live: root.live
                racks: root.racks
                running: root.running
                padConnected: scene.padConnected
                armedReach: root.armedReach
                armedValid: root.armedValid
                selectedContact: root.selectedContact
                shootableContact: root.shootableContact
                onInvoked: ability => touched.post({ ability: ability })
                onTouched: root.device.kind = ActiveDevice.Touch
                onContactChosen: contactId => designate.post({ contact: contactId === game.ownship.targetContact ? "" : contactId })
                onContactTouched: root.device.kind = ActiveDevice.Touch
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
            visible: TouchScreen.available && root.device.touch && root.racks
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

        // The touch range pair, stacked over the stick: up ranges in, down
        // ranges out, the same way round as the wheel and the d-pad. It steps
        // the shared range axis rather than posting anything — the scope is a
        // display, so ranging it never goes near the bus. Seated under the
        // left thumb because the right one now has the HUD's own ability rack,
        // which touch shares with every other device rather than standing up a
        // second one of its own.
        Column {
            id: ranging

            readonly property real arrowSize: Math.max(44, Math.min(root.width, root.height) * 0.08)

            visible: TouchScreen.available && root.device.touch && root.racks
            spacing: ranging.arrowSize * 0.12

            anchors {
                horizontalCenter: stick.horizontalCenter
                bottom: stick.top
                bottomMargin: 16
            }

            TouchArrow {
                width: ranging.arrowSize
                height: width
                up: true
                onTapped: axisRange.step(1)
            }

            TouchArrow {
                width: ranging.arrowSize
                height: width
                up: false
                onTapped: axisRange.step(-1)
            }
        }

        // The launch screen's backdrop: the same live situation display, its
        // picture pushed right and down (briardart's menu-demo geometry) so
        // the demo dogfight plays clear of the title band and the action rail.
        ViewSituation {
            visible: !root.inDuel
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
            // A backdrop behind the title, not an instrument: the demo's marks
            // keep their callsigns and drop the ranges nobody is flying on.
            showTrackRanges: false
            trailsRunning: root.running

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

        visible: !root.inDuel
        focus: root.mode === Mode.Kind.Menu
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

        visible: root.stage === Mode.Kind.Pause
        focus: root.mode === Mode.Kind.Pause
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

        // Stands behind the settings page rather than vanishing under it, as
        // the other two overlays do — out of reach today, since nothing on
        // this screen opens the page, but it costs nothing to be the same
        // shape as its siblings.
        visible: root.stage === Mode.Kind.End
        focus: root.mode === Mode.Kind.End
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
    // to refuse it. Visibility and focus are bound to the mode here, exactly as
    // the other three overlays' are — an imperative hand-off leaves the scene
    // unfocused and the game permanently deaf the moment one exit path forgets
    // to hand it back.
    ViewSettings {
        id: settings

        visible: root.mode === Mode.Kind.Settings
        focus: root.mode === Mode.Kind.Settings
        anchors.fill: parent
        keymap: root.keymap
        loadout: game.ownship.abilities
        device: root.device
        onClosed: root.closeSettings()
    }

    // Returns every input source to rest: the action bindings, and the stick's
    // own axis slots, which it contributes under the axis itself and so the
    // router cannot reach. For leaving — the window going inactive, where the
    // pad route shuts down with it and nothing is heard again until it comes
    // back, so rest is the only honest reading of controls nobody is watching.
    function dropInput() {
        actions.reset();
        axisSteer.invoke(0);
        axisThrottle.invoke(0);
    }

    // For a handover between screens, where the router goes on listening.
    // The same drop, because a key or a pad button released behind an overlay
    // never reports its release and would otherwise stay held for good — and
    // then the analogue controls re-state themselves, because a stick says
    // nothing while it is held still, and dropping it leaves the player
    // holding a lever the game has stopped reading. One is honest about a lost
    // edge; the other would be inventing a centred stick.
    function resyncInput() {
        root.dropInput();
        actions.resync();
    }

    // The launch screen: the demo scenario populates the world itself, one
    // range step out from the tightest so the temperaments' fighting
    // envelopes stay on the picture. Arriving from a paused or decided duel,
    // the demo's own restart sweeps the fight's leavings and reseats ownship
    // for the show.
    // The mission latch is deliberately left alone: rearming it here would
    // only trip again on the next tick, since the judge still reads the spent
    // duel's bandit and the demo tops ownship's hull every frame. It is
    // startDuel() that rearms it, and it does so before entering the duel, so
    // no decided latch can outlive the screen it belongs to.
    function startMenu() {
        root.resyncInput();
        demo.restart();
        // The blasts go out with the fight that lit them; the demo's own
        // rounds light their own.
        weapons.reset();
        // The demo plays an open sky: the duel's arena leaves with the duel.
        root.world.obstacles = [];
        projection.step = 1;
        root.mode = Mode.Kind.Menu;
    }

    // Escape or Start mid-duel: freeze the sim behind the pause menu. Held
    // input is dropped while the bus still runs, exactly as the page does.
    function openPause() {
        root.resyncInput();
        root.mode = Mode.Kind.Pause;
    }

    function resumeDuel() {
        root.mode = Mode.Kind.Duel;
        root.resyncInput();
    }

    // The duel's decision. The judge latches from live model state inside the
    // tick, so this is what turns that latch into the end screen; it runs on
    // either edge, so entering a duel whose latch has not been rearmed lands
    // on the result rather than flying a fight that is already over.
    function judge() {
        if (root.decided && root.live)
            root.mode = Mode.Kind.End;
    }

    // The contacts the designation cycle walks, ordered clockwise off
    // ownship's nose so the walk reads as a sweep across the heading-up scope.
    function selectableTracks(): var {
        const picked = detection.tracks.filter(t => t.selectable);
        picked.sort((a, b) => Geo.wrap180(a.azimuth - game.ownship.heading) - Geo.wrap180(b.azimuth - game.ownship.heading));
        return picked;
    }

    // One cycle press: the next selectable contact around the scope, wrapping,
    // or the one nearest the nose where nothing is selected yet. An empty
    // picture selects nothing and says nothing.
    function cycleTarget(direction: int) {
        const picked = root.selectableTracks();
        if (picked.length === 0)
            return;
        const current = picked.findIndex(t => t.contactId === game.ownship.targetContact);
        let chosen = picked[0];
        if (current < 0) {
            for (let i = 1; i < picked.length; ++i) {
                const off = Math.abs(Geo.wrap180(picked[i].azimuth - game.ownship.heading));
                if (off < Math.abs(Geo.wrap180(chosen.azimuth - game.ownship.heading)))
                    chosen = picked[i];
            }
        } else {
            chosen = picked[(current + direction + picked.length) % picked.length];
        }
        designate.post({ contact: chosen.contactId });
    }

    // New game: rebuild both craft factory-fresh, sweep the whole world —
    // the demo's leavings and the spent craft alike — and enroll the new
    // pair on the game range step. Whatever screen it was ordered from, the
    // one mode write at the end is what leaves the fresh duel running rather
    // than frozen behind that screen. The judge is rearmed before that write,
    // and that order is load-bearing: entering the duel on a latch left
    // standing would drop the player straight back onto the end screen.
    function startDuel() {
        demo.reset();
        game.reset();
        scenario.reset();
        mission.reset();
        // The blasts burn on simulation time, so the one that decided the last
        // duel is still lit when this one opens.
        weapons.reset();
        root.world.clear(null);
        root.world.add(game.ownship);
        for (let i = 0; i < scenario.entities.length; ++i)
            root.world.add(scenario.entities[i]);
        root.world.obstacles = scenario.obstacles;
        projection.step = 2;
        root.mode = Mode.Kind.Duel;
        root.resyncInput();
    }

    // The page stops the sim whatever it is opened over, so a duel it is
    // opened from is paused on the way in rather than dropped back into
    // mid-frame on the way out — the difference between coming back to a
    // RESUME and being handed a fight already in progress. Recording where it
    // was opened from is what DONE returns to, and this is that field's only
    // writer, so the page always has somewhere to go back to.
    //
    // Held input is released while the bus is still running, so the settled
    // steer and throttle post before the simulation stops. Both verbs
    // coalesce, so they publish on resume and the ship never carries a command
    // out of the page that its controls have stopped giving — which is also
    // why nothing clears the queue.
    function openSettings() {
        root.resyncInput();
        root.settingsFrom = root.live ? Mode.Kind.Pause : root.mode;
        root.mode = Mode.Kind.Settings;
    }

    function closeSettings() {
        root.mode = root.settingsFrom;
        root.resyncInput();
    }
}
