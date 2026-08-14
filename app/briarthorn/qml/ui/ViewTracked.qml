import QtQuick
import awen.shapes
import "../model"
import "../themes"

// Radar-lock warning: flashes while a sentry radar holds the ownship inside
// its engagement ring — the sweep that stopped on you, close enough to shoot
// — with an arrow swinging to the site's bearing in the scope's heading-up
// frame and its range beside it. It reads the sentry's own lock rather than
// any sensor product, which is what a warning receiver is: being painted is
// not something a target can miss. A battery that is merely following a
// track it cannot reach raises nothing, or the panel would be lit for most
// of a duel and mean nothing when it mattered. Warn-coloured, not hostile —
// a lock is the seconds before the MISSILE alert, not the missile.
Item {
    id: root

    // The craft the warning speaks for, and the roster scanned for sentries.
    property Entity ownship
    property list<Entity> entities

    // The nearest live sentry holding the ownship, or null for a quiet sky.
    // A dropped lock nulls the sentry's engageTarget the tick it drops, so
    // this needs no timeout of its own.
    readonly property Entity tracker: {
        if (!root.ownship)
            return null;
        let best = null;
        let bestRange = Infinity;
        for (let i = 0; i < root.entities.length; ++i) {
            const site = root.entities[i];
            if (!site.sentry || site.health <= 0 || site.engageTarget !== root.ownship || site.engageHold)
                continue;
            const range = Geo.distance(site, root.ownship);
            if (range < bestRange) {
                best = site;
                bestRange = range;
            }
        }
        return best;
    }

    readonly property bool active: root.tracker !== null

    // Degrees the tracking site sits off the nose — the arrow's swing.
    readonly property real trackerBearing: root.active ? Geo.wrap180(Geo.bearing(root.ownship, root.tracker) - root.ownship.heading) : 0
    readonly property real trackerRange: root.active ? Geo.distance(root.ownship, root.tracker) : 0

    implicitWidth: content.implicitWidth + 32
    implicitHeight: content.implicitHeight + 14
    visible: root.active

    Rectangle {
        anchors.fill: parent
        radius: Style.theme.panelRadius
        color: Style.theme.panelBackground
        border.color: Style.theme.warn
        border.width: 2
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 12

        ShapePolygon {
            anchors.verticalCenter: parent.verticalCenter
            width: 22
            height: width
            rotation: root.trackerBearing
            points: [Qt.point(0, -0.5), Qt.point(0.38, 0.34), Qt.point(0, 0.14), Qt.point(-0.38, 0.34)]
            fillColor: Style.theme.warn
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("TRACKED")
            color: Style.theme.warn
            font { pixelSize: 16; family: Style.monospace; bold: true; letterSpacing: Style.theme.capsTracking }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("%1 KM").arg((root.trackerRange / 1000).toFixed(1))
            color: Style.theme.textBright
            font { pixelSize: 13; family: Style.monospace }
        }
    }

    // A slower breath than the missile warning's flash: the lock asks for a
    // decision, the missile for a reaction, and the eye should be able to
    // tell which from the corner it watches this in.
    SequentialAnimation on opacity {
        running: root.visible
        loops: Animation.Infinite

        NumberAnimation {
            from: 1
            to: 0.45
            duration: 500
        }

        NumberAnimation {
            from: 0.45
            to: 1
            duration: 500
        }
    }

    // The tap-sink the other alerts carry: a press on the warning must not
    // designate whatever flies behind it.
    TapHandler {
        gesturePolicy: TapHandler.ReleaseWithinBounds
    }
}
