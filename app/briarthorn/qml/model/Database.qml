pragma Singleton

import QtQuick

// The per-classification Data rows; dataFor() is the render lookup an
// EntitySymbol draws from, falling back to the unknown-contact diamond.
QtObject {
    id: root

    readonly property Data unknown: Data {
        classification: Classification.Kind.Unknown
        outline: [Qt.point(0, -0.5), Qt.point(0.35, 0), Qt.point(0, 0.5), Qt.point(-0.35, 0)]
        label: "UNK"
    }

    readonly property Data aircraftFighter: Data {
        classification: Classification.Kind.AircraftFighter
        outline: [Qt.point(0, -0.5), Qt.point(0.4, 0.45), Qt.point(0, 0.18), Qt.point(-0.4, 0.45)]
        label: "FIGHTER"
    }

    function dataFor(classification: int): Data {
        switch (classification) {
        case Classification.Kind.AircraftFighter:
            return root.aircraftFighter;
        default:
            return root.unknown;
        }
    }
}
