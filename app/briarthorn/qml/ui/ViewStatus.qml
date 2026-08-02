import QtQuick
import awen.shapes
import "../database"
import "../model"
import "../themes"

// Ownship condition readout: a round instrument that mirrors the corner minimap
// opposite it — same footprint, so the two read as a matched pair and the whole
// thing stays compact on a phone. Two concentric arc dials around the ownship
// symbol — HULL outer (cyan), FUEL inner (gold) — each sweeping 270° and opening
// at the bottom, with the values seated in that open mouth. A low reading shifts
// its ring and value to the warn colour. Reads live from the ownship entity.
Item {
    id: root

    // The craft whose condition this shows.
    property Entity ownship

    readonly property real shortSide: Math.min(width, height)
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real ringWidth: shortSide * 0.055

    readonly property real healthFrac: ownship && ownship.maxHealth > 0 ? Math.max(0, Math.min(1, ownship.health / ownship.maxHealth)) : 0
    readonly property real fuelFrac: ownship && ownship.maxFuel > 0 ? Math.max(0, Math.min(1, ownship.fuel / ownship.maxFuel)) : 0
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

    // Ownship symbol, nose up, lifted just above centre so it clears the mouth
    // readouts below.
    Symbol {
        x: root.cx - width / 2
        y: root.cy - height / 2 - root.shortSide * 0.09
        symbolSize: root.shortSide * 0.26
        classification: root.ownship ? root.ownship.classification : Classification.Kind.AircraftFighter
        side: root.ownship ? root.ownship.side : Side.Kind.Ownship
        showLabel: false
    }

    // Readouts in the open mouth at the bottom: hull number over fuel percent,
    // colour-keyed to their rings.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: root.cy + root.shortSide * 0.08
        spacing: -root.shortSide * 0.01

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ownship ? Math.round(root.ownship.health) : "--"
            color: root.hullLow ? Style.theme.warn : Style.theme.accent
            font { pixelSize: root.shortSide * 0.15; family: Style.monospace; bold: true }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.ownship ? Math.round(root.fuelFrac * 100) + "%" : "--"
            color: root.fuelLow ? Style.theme.warn : Style.theme.fuel
            font.pixelSize: root.shortSide * 0.11
            font.family: Style.monospace
        }
    }
}
