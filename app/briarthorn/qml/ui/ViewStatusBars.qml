import QtQuick
import "../model"
import "../themes"

// Ownship condition as horizontal bars — the tiled HUD's answer to the round
// ViewStatus, reading the same three values against the same warn
// thresholds: HULL, FUEL and SPD, each a label, a bar and its number. A
// white tick on the speed bar marks the commanded throttle; speed closes on
// exactly that mark, so the gap between fill tip and tick is the spool still
// in progress.
Item {
    id: root

    // The craft whose condition this shows.
    property Entity ownship

    readonly property real healthFrac: ownship ? ownship.healthFrac : 0
    readonly property real fuelFrac: ownship ? ownship.fuelFrac : 0
    readonly property real speedFrac: ownship && ownship.topSpeed > 0 ? Math.min(1, ownship.speed / ownship.topSpeed) : 0
    // Clamped here: maneuvers write the entity directly, not through the
    // priced throttle handler.
    readonly property real throttleFrac: ownship ? Math.max(0, Math.min(1, ownship.commandedThrottle)) : 0
    readonly property bool hullLow: healthFrac <= 0.3
    readonly property bool fuelLow: fuelFrac <= 0.2

    implicitWidth: 220
    implicitHeight: rows.implicitHeight

    Column {
        id: rows

        anchors.fill: parent
        spacing: Math.max(6, root.height * 0.08)

        BarRow {
            label: qsTr("HULL")
            frac: root.healthFrac
            tint: root.hullLow ? Style.theme.warn : Style.theme.accent
            value: root.ownship ? Math.round(root.ownship.health).toString() : "--"
        }

        BarRow {
            label: qsTr("FUEL")
            frac: root.fuelFrac
            tint: root.fuelLow ? Style.theme.warn : Style.theme.fuel
            value: root.ownship ? Math.round(root.fuelFrac * 100) + "%" : "--"
        }

        BarRow {
            label: qsTr("SPD")
            frac: root.speedFrac
            tint: Style.theme.accentBright
            value: root.ownship ? Math.round(root.ownship.speed).toString() : "--"
            tick: root.throttleFrac
        }
    }

    // One reading: label left, bar filling the middle, the number right —
    // fixed side columns, so the three bars align into one instrument.
    component BarRow: Item {
        id: row

        property string label: ""
        property real frac: 0
        property color tint: Style.theme.accent
        property string value: ""

        // The commanded-throttle tick's position along the bar, or -1 for a
        // reading with no setpoint to mark.
        property real tick: -1

        width: rows.width
        height: Math.max(16, (rows.height - 2 * rows.spacing) / 3)

        Text {
            id: caption

            width: 34
            text: row.label
            color: Style.theme.textLabel
            font { pixelSize: 11; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            id: track

            height: Math.max(4, row.height * 0.32)
            color: Style.theme.gaugeTrack

            anchors {
                left: caption.right
                right: reading.left
                leftMargin: 8
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }

            Rectangle {
                width: track.width * Math.max(0, Math.min(1, row.frac))
                height: parent.height
                color: row.tint
            }

            // The setpoint tick, proud of the bar so it reads over track and
            // fill exactly as the round gauge's bug does.
            Rectangle {
                visible: row.tick >= 0
                width: 2
                height: track.height + Math.max(4, row.height * 0.24)
                x: track.width * Math.max(0, Math.min(1, row.tick)) - width / 2
                anchors.verticalCenter: parent.verticalCenter
                color: Style.theme.textBright
            }
        }

        Text {
            id: reading

            width: 44
            horizontalAlignment: Text.AlignRight
            text: row.value
            color: row.tint
            font { pixelSize: 12; family: Style.monospace; bold: true }
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        }
    }
}
