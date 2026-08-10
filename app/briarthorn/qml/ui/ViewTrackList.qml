pragma ComponentBehavior: Bound

import QtQuick
import "../database"
import "../model"
import "../themes"

// The track list tile: every craft on the picture as a row — callsign, true
// bearing, range, what it is, and its hull where the sweep reads one. Rows
// order by callsign, not by range: a selection list must hold still under
// the pointer about to tap it, and the scope already presents range
// spatially. A row tap reports the pick; the list never touches the bus.
Item {
    id: root

    // The picture, the designation to highlight, and the pick going out.
    property list<Track> tracks
    property string selectedContact: ""

    signal chosen(string contactId)

    // The listed tracks: craft and unresolved returns — munitions and decoys
    // plot on the scope but would swamp the two rows that matter here. This
    // binding must read nothing that moves per tick (no range, no azimuth),
    // so it recomputes on membership and resolution changes only; the live
    // fields bind inside each row.
    readonly property var rows: {
        const picked = [];
        for (let i = 0; i < root.tracks.length; ++i) {
            const track = root.tracks[i];
            const def = Database.entityDataFor(track.classification);
            if (track.classification === Classification.Kind.Unknown || (def !== null && def.hullGauge))
                picked.push(track);
        }
        picked.sort((a, b) => a.contactId < b.contactId ? -1 : a.contactId > b.contactId ? 1 : 0);
        return picked;
    }

    // The header, and one row per listed track.
    Column {
        anchors.fill: parent
        spacing: 2

        Item {
            width: parent.width
            height: 18

            Text {
                text: qsTr("ID")
                color: Style.theme.textLabel
                font { pixelSize: 10; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
            }

            Text {
                x: parent.width - 96
                text: qsTr("BRG")
                color: Style.theme.textLabel
                font { pixelSize: 10; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
            }

            Text {
                anchors.right: parent.right
                text: qsTr("RNG")
                color: Style.theme.textLabel
                font { pixelSize: 10; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: Style.theme.rangeRing
                anchors.bottom: parent.bottom
            }
        }

        Repeater {
            model: root.rows

            TrackRow {
                required property Track modelData

                width: parent.width
                track: modelData
            }
        }
    }

    // The picture with nothing worth listing on it.
    Text {
        anchors.centerIn: parent
        visible: root.rows.length === 0
        text: qsTr("NO CONTACTS")
        color: Style.theme.textMuted
        font { pixelSize: 12; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
    }

    // One contact: callsign, bearing and range quantized for reading, its
    // kind, and the hull bar where a reading exists. The selected row wears
    // the settings page's highlight, so "chosen" reads the same everywhere.
    component TrackRow: Rectangle {
        id: row

        required property Track track

        readonly property bool selected: root.selectedContact !== "" && row.track.contactId === root.selectedContact
        readonly property color side: root.sideColor(row.track.side)

        height: 34
        radius: Style.theme.panelRadius
        color: row.selected ? Style.theme.panelBackground : "transparent"
        border.width: row.selected ? 1 : 0
        border.color: Style.theme.accent

        MouseArea {
            anchors.fill: parent
            onClicked: root.chosen(row.track.contactId)
        }

        Text {
            x: 4
            y: 3
            text: row.track.contactId
            color: row.side
            font { pixelSize: 11; bold: true; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }

        Text {
            x: parent.width - 96
            y: 3
            text: String(Math.round(row.track.azimuth) % 360).padStart(3, "0")
            color: Style.theme.textPrimary
            font { pixelSize: 11; family: Style.monospace }
        }

        Text {
            y: 3
            anchors.right: parent.right
            anchors.rightMargin: 4
            text: (row.track.range / 1000).toFixed(1)
            color: Style.theme.textPrimary
            font { pixelSize: 11; family: Style.monospace }
        }

        // The kind, as the sweep reads it; UNKNOWN until the volume resolves.
        Text {
            y: 18
            anchors.right: parent.right
            anchors.rightMargin: 4
            text: {
                const def = Database.entityDataFor(row.track.classification);
                return def !== null ? def.label : "";
            }
            color: Style.theme.textLabel
            font { pixelSize: 9; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }

        // The hull reading, gone with the resolution exactly as the scope's
        // own gauge is.
        Rectangle {
            visible: row.track.maxHealth > 0
            x: 4
            y: 23
            width: 52
            height: 3
            color: Style.theme.gaugeTrack

            Rectangle {
                width: parent.width * row.track.healthFrac
                height: parent.height
                color: row.track.healthFrac <= 0.3 ? Style.theme.warn : row.side
            }
        }
    }

    // A row's callsign takes its faction colour, matching the scope's marks.
    function sideColor(side: int): color {
        switch (side) {
        case Side.Kind.Ownship:
            return Style.theme.factionOwnship;
        case Side.Kind.Friendly:
            return Style.theme.factionFriendly;
        case Side.Kind.Neutral:
            return Style.theme.factionNeutral;
        case Side.Kind.Hostile:
            return Style.theme.factionHostile;
        default:
            return Style.theme.factionUnknown;
        }
    }
}
