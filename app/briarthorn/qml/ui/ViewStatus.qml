import QtQuick
import awen.shapes
import "../model"
import "../themes"

// Ownship condition readout: a round instrument that mirrors the corner minimap
// opposite it — same footprint, so the two read as a matched pair and the whole
// thing stays compact on a phone. Two concentric arc dials around the ownship
// symbol — HULL outer (cyan), FUEL inner (gold) — each sweeping 270° and opening
// at the bottom, with the values seated in that open mouth. A low reading shifts
// its ring and value to the warn colour. Reads live from the ownship entity.
Item {
    id: view

    // The craft whose condition this shows.
    property Entity ownship

    implicitWidth: 150
    implicitHeight: 150

    readonly property real shortSide: Math.min(width, height)
    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real ringWidth: shortSide * 0.055

    readonly property real healthFrac: ownship && ownship.maxHealth > 0 ? Math.max(0, Math.min(1, ownship.health / ownship.maxHealth)) : 0
    readonly property real fuelFrac: ownship && ownship.maxFuel > 0 ? Math.max(0, Math.min(1, ownship.fuel / ownship.maxFuel)) : 0
    readonly property bool hullLow: healthFrac <= 0.3
    readonly property bool fuelLow: fuelFrac <= 0.2

    // HULL — the outer dial.
    ShapeGauge {
        anchors.fill: parent
        centerX: view.cx
        centerY: view.cy
        radius: view.shortSide * 0.44
        strokeWidth: view.ringWidth
        angleStart: 225
        angleSweep: 270
        value: view.healthFrac
        trackColor: Style.theme.gaugeTrack
        fillColor: view.hullLow ? Style.theme.warn : Style.theme.accent
    }

    // FUEL — the inner dial, concentric inside the hull ring.
    ShapeGauge {
        anchors.fill: parent
        centerX: view.cx
        centerY: view.cy
        radius: view.shortSide * 0.355
        strokeWidth: view.ringWidth
        angleStart: 225
        angleSweep: 270
        value: view.fuelFrac
        trackColor: Style.theme.gaugeTrack
        fillColor: view.fuelLow ? Style.theme.warn : Style.theme.fuel
    }

    // Ownship symbol, nose up, lifted just above centre so it clears the mouth
    // readouts below.
    Symbol {
        x: view.cx - width / 2
        y: view.cy - height / 2 - view.shortSide * 0.09
        symbolSize: view.shortSide * 0.26
        classification: view.ownship ? view.ownship.classification : Classification.Kind.AircraftFighter
        side: view.ownship ? view.ownship.side : Side.Kind.Ownship
        showLabel: false
    }

    // Readouts in the open mouth at the bottom: hull number over fuel percent,
    // colour-keyed to their rings.
    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        y: view.cy + view.shortSide * 0.08
        spacing: -view.shortSide * 0.01

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: view.ownship ? Math.round(view.ownship.health) : "--"
            color: view.hullLow ? Style.theme.warn : Style.theme.accent
            font.pixelSize: view.shortSide * 0.15
            font.family: "Consolas"
            font.bold: true
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: view.ownship ? Math.round(view.fuelFrac * 100) + "%" : "--"
            color: view.fuelLow ? Style.theme.warn : Style.theme.fuel
            font.pixelSize: view.shortSide * 0.11
            font.family: "Consolas"
        }
    }
}
