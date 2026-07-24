pragma Singleton

import QtQuick

// The per-classification Data rows; dataFor() is the render lookup a
// Symbol draws from, falling back to the unknown-contact diamond.
QtObject {
    id: root

    readonly property Data unknown: Data {
        classification: Classification.Kind.Unknown
        outline: [Qt.point(0, -0.5), Qt.point(0.35, 0), Qt.point(0, 0.5), Qt.point(-0.35, 0)]
        label: qsTr("UNK")
    }

    readonly property Data aircraftFighter: Data {
        classification: Classification.Kind.AircraftFighter
        outline: [Qt.point(0, -0.5), Qt.point(0.4, 0.45), Qt.point(0, 0.18), Qt.point(-0.4, 0.45)]
        label: qsTr("FIGHTER")
    }

    // Weapon rows: briardart's missile tuning carried over as direct
    // quantities. The guided round outruns the kinetic but hits softer; the
    // kinetic's big warhead makes up for the dumb fuze.
    readonly property DataWeapon missileGuided: DataWeapon {
        classification: Classification.Kind.MissileGuided
        outline: [Qt.point(0, -0.5), Qt.point(0.15, 0.5), Qt.point(-0.15, 0.5)]
        label: qsTr("MSL")
        symbolScale: 0.55
        speed: 1800
        turnRate: 24
        duration: 24
        guided: true
        seekerRange: 90000
        fuzeRange: 500
        fuzeTime: 0.3
        damage: 55
        blastRadius: 900
    }

    readonly property DataWeapon missileKinetic: DataWeapon {
        classification: Classification.Kind.MissileKinetic
        outline: [Qt.point(0, -0.5), Qt.point(0.15, 0.5), Qt.point(-0.15, 0.5)]
        label: qsTr("MSL")
        symbolScale: 0.55
        speed: 1000
        duration: 18
        fuzeRange: 1200
        fuzeTime: 0.3
        damage: 80
        blastRadius: 2500
    }

    readonly property Data decoy: Data {
        classification: Classification.Kind.Decoy
        outline: [Qt.point(0, -0.35), Qt.point(0.35, 0), Qt.point(0, 0.35), Qt.point(-0.35, 0)]
        label: qsTr("CM")
        symbolScale: 0.45
    }

    function dataFor(classification: int): Data {
        switch (classification) {
        case Classification.Kind.AircraftFighter:
            return root.aircraftFighter;
        case Classification.Kind.MissileGuided:
            return root.missileGuided;
        case Classification.Kind.MissileKinetic:
            return root.missileKinetic;
        case Classification.Kind.Decoy:
            return root.decoy;
        default:
            return root.unknown;
        }
    }

    // The weapon row behind a launchable classification, or null.
    function weaponDataFor(classification: int): DataWeapon {
        switch (classification) {
        case Classification.Kind.MissileGuided:
            return root.missileGuided;
        case Classification.Kind.MissileKinetic:
            return root.missileKinetic;
        default:
            return null;
        }
    }
}
