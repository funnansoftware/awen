import QtQuick
import "../model"
import "../themes"

// The launch-authority readout: while the pilot is holding a weapon armed,
// which one it is and what it is waiting on before it leaves the rail. The
// sentence behind the rack's one-word state and the scope's caution-coloured
// envelope — the rack says NO LOCK and the scope shows where a lock would have
// to be, and this says it in words, so a player who has just pressed and seen
// nothing happen is told why rather than left to infer it. Silent whenever
// nothing is armed: it answers a press, it is not standing chrome.
Item {
    id: root

    // The craft whose armed slot this announces.
    property Entity ownship

    readonly property AbilitySlot slot: root.ownship ? root.ownship.armedAbility : null
    readonly property bool active: root.slot !== null
    readonly property bool valid: root.active && root.slot.valid

    readonly property string weapon: root.active && root.slot.def ? root.slot.def.label : ""

    // What the shot is held on, in words. The lock case is the moment before
    // the round leaves, so it reads as the answer the other three are waiting
    // to become.
    readonly property string reason: {
        if (!root.active)
            return "";
        switch (root.slot.impediment) {
        case AbilitySlot.Impediment.Cooling:
            return qsTr("RELOADING");
        case AbilitySlot.Impediment.Empty:
            return qsTr("NO ROUNDS");
        case AbilitySlot.Impediment.NoLock:
            return qsTr("NO TARGET IN RADAR VOLUME");
        case AbilitySlot.Impediment.Distant:
            return qsTr("TARGET OUT OF MISSILE RANGE");
        case AbilitySlot.Impediment.NoTarget:
            return qsTr("NO TARGET SELECTED");
        default:
            return root.slot.lock !== null ? qsTr("LOCK %1").arg(root.slot.lock.callsign) : qsTr("CLEAR TO FIRE");
        }
    }

    readonly property color tint: root.valid ? Style.theme.armValid : Style.theme.armInvalid

    // The breathing, read only while the shot is held — a valid readout holds
    // steady, so the property is never bound over the animation driving it.
    property real pulse: 1

    // The widest the panel may draw, or -1 for no ceiling. Measured off the
    // captions' own extents rather than off the laid-out row, so capping the
    // panel narrows the reason instead of feeding the row's width back into
    // the size that set it.
    property real maximumWidth: -1

    readonly property real padding: 16
    readonly property real captions: name.implicitWidth + content.spacing + cause.implicitWidth

    implicitWidth: root.captions + root.padding * 2
    implicitHeight: content.implicitHeight + 14
    width: root.maximumWidth < 0 ? root.implicitWidth : Math.min(root.implicitWidth, root.maximumWidth)
    visible: root.active
    opacity: root.valid ? 1 : root.pulse

    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.panelBackground
        border.color: root.tint
        border.width: 2
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 12

        Text {
            id: name

            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 ARMED").arg(root.weapon)
            color: root.tint
            font { pixelSize: 15; family: Style.monospace; bold: true; letterSpacing: Style.theme.capsTracking }
        }

        // The one caption that gives way on a narrow display: the weapon's own
        // name and its state must stay whole, and the scope is showing the
        // same answer in colour beside it.
        Text {
            id: cause

            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(0, root.width - root.padding * 2 - name.implicitWidth - content.spacing)
            elide: Text.ElideRight
            text: root.reason
            color: Style.theme.textBright
            font { pixelSize: 13; family: Style.monospace; letterSpacing: Style.theme.capsTracking }
        }
    }

    // Breathing while the shot is held, steady the instant it can fly: the
    // same beat the scope's envelope keeps, so the two read as one state.
    SequentialAnimation on pulse {
        running: root.visible && !root.valid
        loops: Animation.Infinite

        NumberAnimation { from: 1; to: 0.4; duration: 300 }
        NumberAnimation { from: 0.4; to: 1; duration: 300 }
    }

    // The tap-sink: the panel stands over the scope's upper sector, and the
    // mark hit areas listen under the whole display — a press on the readout
    // must not designate whatever flies behind it.
    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
    }
}
