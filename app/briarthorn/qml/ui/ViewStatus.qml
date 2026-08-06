import QtQuick
import awen.shapes
import "../database"
import "../model"
import "../themes"

// Ownship condition readout: a round instrument that mirrors the corner minimap
// opposite it — same footprint, so the two read as a matched pair and the whole
// thing stays compact on a phone. Three concentric arc dials around the ownship
// symbol — HULL outer (cyan), FUEL middle (gold), SPEED inner (pale cyan) —
// each sweeping 270° and opening at the bottom, with the values seated in that
// open mouth, stacked inner-to-outer so each number sits with its ring —
// speed smallest by the symbol, hull largest at the rim. A white tick on the
// speed ring marks the commanded throttle; speed closes on exactly that mark,
// so the gap to the fill tip is the spool still in progress. A low hull or
// fuel reading shifts its ring and value to the warn colour. Reads live from
// the ownship entity.
Item {
    id: root

    // The craft whose condition this shows.
    property Entity ownship

    readonly property real shortSide: Math.min(width, height)
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real ringWidth: shortSide * 0.055

    readonly property real healthFrac: ownship ? ownship.healthFrac : 0
    readonly property real fuelFrac: ownship ? ownship.fuelFrac : 0
    readonly property real speedFrac: ownship && ownship.topSpeed > 0 ? Math.min(1, ownship.speed / ownship.topSpeed) : 0
    // Clamped here: maneuvers write the entity directly, not through the
    // priced throttle handler.
    readonly property real throttleFrac: ownship ? Math.max(0, Math.min(1, ownship.commandedThrottle)) : 0
    readonly property bool hullLow: healthFrac <= 0.3
    readonly property bool fuelLow: fuelFrac <= 0.2

    implicitWidth: 150
    implicitHeight: 150

    // HULL — the outer dial.
    ShapeGauge {
        anchors.fill: parent
        centerX: root.cx
        centerY: root.cy
        radius: root.shortSide * 0.44
        strokeWidth: root.ringWidth
        angleStart: 225
        angleSweep: 270
        value: root.healthFrac
        trackColor: Style.theme.gaugeTrack
        fillColor: root.hullLow ? Style.theme.warn : Style.theme.accent
    }

    // FUEL — the inner dial, concentric inside the hull ring.
    ShapeGauge {
        anchors.fill: parent
        centerX: root.cx
        centerY: root.cy
        radius: root.shortSide * 0.355
        strokeWidth: root.ringWidth
        angleStart: 225
        angleSweep: 270
        value: root.fuelFrac
        trackColor: Style.theme.gaugeTrack
        fillColor: root.fuelLow ? Style.theme.warn : Style.theme.fuel
    }

    // SPEED — the innermost dial. No warn colour: nothing in the rules
    // degrades speed, so unlike hull and fuel there is no threshold to flag.
    ShapeGauge {
        id: speedGauge

        anchors.fill: parent
        centerX: root.cx
        centerY: root.cy
        radius: root.shortSide * 0.27
        strokeWidth: root.ringWidth
        angleStart: 225
        angleSweep: 270
        value: root.speedFrac
        trackColor: Style.theme.gaugeTrack
        fillColor: Style.theme.accentBright
    }

    // The commanded-throttle bug: a radial tick riding the speed ring at the
    // setpoint's bearing, proud of the stroke so it reads over track and fill.
    Rectangle {
        readonly property real bearing: 225 + 270 * root.throttleFrac
        readonly property point mark: speedGauge.pointAt(bearing, speedGauge.radius)

        width: 2
        height: root.ringWidth + root.shortSide * 0.02
        x: mark.x - width / 2
        y: mark.y - height / 2
        rotation: bearing
        color: Style.theme.textBright
    }

    // Ownship symbol, nose up, lifted just above centre so it clears the mouth
    // readouts below and sized to sit inside the speed ring.
    Symbol {
        x: root.cx - width / 2
        y: root.cy - height / 2 - root.shortSide * 0.09
        symbolSize: root.shortSide * 0.24
        classification: root.ownship ? root.ownship.classification : Classification.Kind.AircraftFighter
        side: root.ownship ? root.ownship.side : Side.Kind.Ownship
        showLabel: false
    }

    // Readouts in the open mouth at the bottom, stacked inner-to-outer like
    // the rings they read: speed in m/s by the symbol, then fuel percent, then
    // the hull number at the rim, colour-keyed to their rings.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy + root.shortSide * 0.08
        spacing: -root.shortSide * 0.01

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ownship ? Math.round(root.ownship.speed) : "--"
            color: Style.theme.accentBright
            font.pixelSize: Math.max(9, root.shortSide * 0.085)
            font.family: Style.monospace
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ownship ? Math.round(root.fuelFrac * 100) + "%" : "--"
            color: root.fuelLow ? Style.theme.warn : Style.theme.fuel
            font.pixelSize: Math.max(9, root.shortSide * 0.11)
            font.family: Style.monospace
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ownship ? Math.round(root.ownship.health) : "--"
            color: root.hullLow ? Style.theme.warn : Style.theme.accent
            font { pixelSize: Math.max(11, root.shortSide * 0.15); family: Style.monospace; bold: true }
        }
    }
}
