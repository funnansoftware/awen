import QtQuick
import "../input"
import "../model"
import "../themes"

// The floating duel HUD: instruments floated over a full-bleed attack scope —
// the round condition gauge and corner minimap as a matched pair, the ability
// rack docked bottom-right, the flight hints along the bottom and the alert
// channel top-centre. One of the two compositions Main loads under the top
// bar; the tiled portal layout is the other, and the one the game opens on.
// Views emit and Main posts — no command bus is touched from here.
Item {
    id: root

    // The flown craft, the input/display context, and the world state the
    // instruments read. bandHeight is the top bar's height — the strip this
    // composition starts below.
    required property Entity ownship
    required property Keymap keymap
    required property ActiveDevice device
    required property RangeProjection projection
    property list<Track> tracks
    property list<Entity> entities
    property list<Detonation> detonations
    property list<Obstacle> obstacles
    property real bandHeight: 0

    // The shell's predicates, passed down rather than re-derived: whether the
    // duel is live under the player's hands, whether the hand controls draw,
    // whether the sim integrates, and whether a controller is connected.
    property bool live: false
    property bool racks: false
    property bool running: true
    property bool padConnected: false

    // The armed weapon's cues and the designation the scope's cursor stands
    // on, all computed by the shell.
    property real armedReach: 0
    property bool armedValid: false
    property string selectedContact: ""
    property string shootableContact: ""

    // The ability rack's press, its release and its touch report, and the
    // scope's designation tap and its own touch report — Main routes them
    // all.
    signal invoked(string ability)
    signal released(string ability)
    signal touched
    signal contactChosen(string contactId)
    signal contactTouched

    // The one side both round corner instruments (condition gauge, minimap)
    // draw at, floored where the readouts inside them would shrink
    // illegible — a single property, so the pair stays a pair structurally.
    readonly property real instrumentSide: Math.max(110, Math.min(root.width, root.height) * 0.22)

    // The attack scope: the game's main centre display. Rings, ownship's
    // radar cone, the heading-up track picture and ownship pinned at the
    // dropped centre — all composed by ViewSituation on the shared
    // projection. It fills the area below the bar, with a gap so a track
    // plotting along the top edge clears the bar, and clips so nothing ever
    // renders up into it.
    ViewSituationAttack {
        clip: true
        projection: root.projection
        observer: root.ownship
        tracks: root.tracks
        entities: root.entities
        detonations: root.detonations
        obstacles: root.obstacles
        symbolSize: height * 0.04
        trailsRunning: root.running
        armedReach: root.armedReach
        armedValid: root.armedValid
        shootableContact: root.shootableContact
        selectedContact: root.selectedContact
        // Live only: a tap on the frozen scope behind an overlay must not
        // queue a designation that lands on resume.
        selectionEnabled: root.live
        onTrackTapped: contactId => root.contactChosen(contactId)
        onTrackTouched: root.contactTouched()

        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            topMargin: root.bandHeight + 16
            bottom: parent.bottom
        }
    }

    // Ownship condition readout, top-left: a round dual-arc gauge (hull +
    // fuel) on the shared instrument side, so it and the minimap opposite
    // read as a matched, compact pair. Dropped below the top band.
    ViewStatus {
        width: root.instrumentSide
        height: width
        ownship: root.ownship

        anchors {
            left: parent.left
            leftMargin: 16
            top: parent.top
            topMargin: root.bandHeight + 12
        }
    }

    // The alert channel, top-centre under the band: the one place both a
    // touch player and a desktop player are already looking.
    ViewAlerts {
        ownship: root.ownship
        entities: root.entities
        // Never off the edge of a phone: the reason elides instead.
        maximumWidth: root.width - 32

        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: root.bandHeight + 12
        }
    }

    // The ability rack, bottom-right: one square button per carried
    // ability, capped with the key or pad button that fires it and posting
    // the same ability record those bindings post — no second invocation
    // path. A thumb landing on one hands the HUD back to the touch
    // controls and presses the very same button. Docked in the corner rather
    // than centred: the scope's centre column carries ownship, its pulse, the
    // decoys it pops and the pursuer's sector, and the rack is captions and
    // clocks, so it is what gives way.
    ViewAbilities {
        id: abilities

        // How far ownship's acquisition pulse draws past the scope centre
        // (ViewSituation's pulse ring); the rack reaches in from its margin
        // no further than the pulse's edge.
        readonly property real pulseReach: 48

        visible: root.racks
        // Floored at a thumb's target, because a thumb is one of the things
        // pressing it, and sized so the rack clears ownship's own bearing line
        // as well as its column on any window taller than about 720.
        buttonSize: Math.max(44, Math.min(root.width, root.height) * 0.07)
        // A craft carrying six abilities shrinks its buttons rather than
        // growing across the scope centre.
        maximumWidth: root.width / 2 - abilities.pulseReach - abilities.anchors.margins
        keymap: root.keymap
        loadout: root.ownship.abilities
        device: root.device
        onInvoked: ability => root.invoked(ability)
        onReleased: ability => root.released(ability)
        onTouched: root.touched()

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
    // display. A touch device flies from the stick and the rack under its
    // thumbs and has no binding to caption, so the line gives way there even
    // though the rack it sits beside does not.
    ViewHints {
        visible: root.racks && !root.device.touch
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

    // The corner minimap, top-right — mirroring the round condition gauge in
    // the opposite corner. It shares the attack scope's projection, so it
    // ranges with it.
    ViewSituationOverview {
        id: minimap

        width: root.instrumentSide
        height: width

        projection: root.projection
        observer: root.ownship
        tracks: root.tracks
        obstacles: root.obstacles

        // The envelope mirrors onto the overview with everything else the
        // minimap keeps; the cursor does not, because a mark drawn this
        // small has no room to stand one off.
        armedReach: root.armedReach
        armedValid: root.armedValid

        anchors {
            right: parent.right
            rightMargin: 16
            top: parent.top
            topMargin: root.bandHeight + 12
        }
    }

    // The controller lamp, tucked under the minimap on the right; lights up
    // when a controller is connected, so the gamepad path is visible.
    Text {
        text: qsTr("controller connected")
        color: Style.theme.textLabel
        font { pixelSize: 12; family: Style.monospace }
        visible: root.padConnected

        anchors {
            right: parent.right
            rightMargin: 16
            top: minimap.bottom
            topMargin: 6
        }
    }
}
