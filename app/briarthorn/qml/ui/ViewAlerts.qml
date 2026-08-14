import QtQuick
import "../model"

// The alert channel: four readouts stacked in the order the pilot has to
// act — terrain first, because a missile can be beaten and a wall cannot;
// the missile warning next; the radar-lock warning under it, since a lock is
// only the promise of a missile; the arming readout last, since it answers a
// press the others interrupt. A Column rather than a chain of anchors, so
// an alert that is not up takes no room and the ones below close over it.
// Shared by both HUD compositions; the caller anchors it where its players
// are already looking.
Column {
    id: root

    // The craft the readouts speak for, the roster the lock warning scans
    // for sentries, and the widest the arming panel may draw before its
    // reason elides.
    required property Entity ownship
    property list<Entity> entities
    property real maximumWidth: -1

    spacing: 12

    ViewTerrain {
        id: terrainAlert

        anchors.horizontalCenter: parent.horizontalCenter
        visible: terrainAlert.active
        ownship: root.ownship
    }

    ViewThreat {
        id: threatAlert

        anchors.horizontalCenter: parent.horizontalCenter
        visible: threatAlert.active
        ownship: root.ownship
    }

    ViewTracked {
        id: trackedAlert

        anchors.horizontalCenter: parent.horizontalCenter
        visible: trackedAlert.active
        ownship: root.ownship
        entities: root.entities
    }

    ViewArming {
        id: armingAlert

        anchors.horizontalCenter: parent.horizontalCenter
        visible: armingAlert.active
        ownship: root.ownship
        maximumWidth: root.maximumWidth
    }
}
