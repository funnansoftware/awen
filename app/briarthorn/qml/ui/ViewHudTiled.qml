import QtQuick
import "../input"
import "../model"
import "../themes"

// The tiled portal HUD: every instrument in a bounded, bordered tile, edge
// to edge — condition bars over the track list on the left, the attack
// scope filling the centre with the alerts overlaid, and the minimap over
// the stores tile on the right, whose ability buttons land in the corner
// under the right thumb. The other of the two compositions Main loads under
// the top bar; desktop-first, with the narrow-screen collapse deliberately
// deferred to the overlay layout.
Item {
    id: root

    // The flown craft, the input/display context, and the world state the
    // tiles read. bandHeight is the top bar's height — the strip the grid
    // starts below.
    required property Entity ownship
    required property Keymap keymap
    required property ActiveDevice device
    required property RangeProjection projection
    property list<Track> tracks
    property list<Entity> entities
    property list<Detonation> detonations
    property list<Obstacle> obstacles
    property real bandHeight: 0

    // The shell's predicates, passed down rather than re-derived.
    property bool live: false
    property bool racks: false
    property bool running: true
    property bool padConnected: false

    // The armed weapon's cues and the designation, computed by the shell.
    property real armedReach: 0
    property bool armedValid: false
    property string selectedContact: ""
    property string shootableContact: ""

    // The rack's press and touch report, and the designation pick and its
    // touch report — from the scope's marks or (later) the track list's
    // rows, one contract either way. Main routes all four.
    signal invoked(string ability)
    signal touched
    signal contactChosen(string contactId)
    signal contactTouched

    // The grid: fixed frames sized by the window, never by content, so the
    // glass reads as one instrument panel however the fight is going.
    readonly property real gutter: 8
    readonly property real leftWidth: Math.max(180, width * 0.23)
    readonly property real rightWidth: Math.max(200, width * 0.24)
    readonly property real gridTop: root.bandHeight + root.gutter
    readonly property real columnHeight: height - gridTop - gutter

    // The condition tile, top-left.
    Tile {
        id: condition

        label: qsTr("COND")
        x: root.gutter
        y: root.gridTop
        width: root.leftWidth
        height: Math.max(120, root.columnHeight * 0.24)
    }

    // The track list tile, filling the left column below the condition bars.
    Tile {
        id: trackList

        label: qsTr("TRACKS")
        x: root.gutter
        y: condition.y + condition.height + root.gutter
        width: root.leftWidth
        height: root.columnHeight - condition.height - root.gutter
    }

    // The attack scope tile, centre: the full-feature situation display
    // retuned for a bounded, near-square frame — the ring capped so
    // gutter-clamped symbols stay inside it, ownship dropped toward the
    // tile's foot so the forward sector still dominates.
    Tile {
        id: attack

        label: qsTr("ATTACK")
        x: condition.x + condition.width + root.gutter
        y: root.gridTop
        width: map.x - x - root.gutter
        height: root.columnHeight

        ViewSituation {
            anchors.fill: parent
            projection: root.projection
            observer: root.ownship
            tracks: root.tracks
            entities: root.entities
            detonations: root.detonations
            obstacles: root.obstacles
            radiusFraction: Math.min(0.48, (width / 2 - symbolSize * 2.2) / Math.min(width, height))
            verticalShift: 0.2
            symbolSize: height * 0.04
            trailsRunning: root.running
            armedReach: root.armedReach
            armedValid: root.armedValid
            shootableContact: root.shootableContact
            selectedContact: root.selectedContact
            selectionEnabled: root.live
            onTrackTapped: contactId => root.contactChosen(contactId)
            onTrackTouched: root.contactTouched()
        }

        // The alert channel overlays the scope's top — the one place the
        // pilot is already looking — exactly as it does on the overlay HUD.
        ViewAlerts {
            z: 1
            ownship: root.ownship
            maximumWidth: attack.width - 32

            anchors {
                horizontalCenter: parent.horizontalCenter
                top: parent.top
                topMargin: 12
            }
        }
    }

    // The minimap tile, top-right, on the shared projection.
    Tile {
        id: map

        label: qsTr("MAP")
        x: root.width - root.rightWidth - root.gutter
        y: root.gridTop
        width: root.rightWidth
        height: Math.min(root.rightWidth, root.columnHeight * 0.45)

        ViewSituationOverview {
            anchors.fill: parent
            projection: root.projection
            observer: root.ownship
            tracks: root.tracks
            obstacles: root.obstacles
            armedReach: root.armedReach
            armedValid: root.armedValid
        }
    }

    // The stores tile, filling the right column below the map: the one
    // state-driven frame — armed colours while a shot is held — with the
    // ability buttons seated at its foot, the best reach the right thumb
    // has. The stores picture itself lands with ViewStores.
    Tile {
        id: stores

        readonly property AbilitySlot armedSlot: root.ownship.armedAbility

        label: qsTr("SMS")
        x: map.x
        y: map.y + map.height + root.gutter
        width: root.rightWidth
        height: root.columnHeight - map.height - root.gutter
        borderColor: stores.armedSlot ? (stores.armedSlot.valid ? Style.theme.armValid : Style.theme.armInvalid) : Style.theme.rangeRing
        borderWidth: stores.armedSlot ? 2 : 1

        ViewAbilities {
            visible: !root.device.touch && root.racks
            buttonSize: 64
            maximumWidth: stores.contentItem.width
            keymap: root.keymap
            loadout: root.ownship.abilities
            device: root.device
            onInvoked: ability => root.invoked(ability)
            onTouched: root.touched()

            anchors {
                right: parent.right
                bottom: parent.bottom
                bottomMargin: 12
            }
        }
    }
}
