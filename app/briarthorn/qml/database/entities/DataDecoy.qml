import QtQuick
import ".."

// Radar lure: no stealth at all, so it is the loudest return in the sky and
// steals a seeker's lock. Popped by a countermeasure ability, never flown.
DataEntity {
    classification: Classification.Kind.Decoy
    outline: [Qt.point(0, -0.35), Qt.point(0.35, 0), Qt.point(0, 0.35), Qt.point(-0.35, 0)]
    label: qsTr("CM")
    symbolScale: 0.45

    stats: Stats {
        durable: 1 // 20 hp: anything that reaches it kills it
        stealth: 0 // the whole point — louder than what it is covering
    }
}
