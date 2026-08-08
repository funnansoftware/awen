import QtQuick
import ".."

// Radar lure: a return wearing the signature of whatever popped it —
// SystemCountermeasure spawns each one with the deployer's own stealth
// rating, so no seeker can tell the two apart by loudness and takes whichever
// is nearer instead. It is placed between the deployer and the round it
// answers, which makes a pop a maneuver rather than a magic word: it holds
// the lock only while the deployer keeps opening the range on it. Popped by
// a countermeasure ability, never flown.
DataEntity {
    id: root

    classification: Classification.Kind.Decoy
    decoy: true
    outline: [Qt.point(0, -0.35), Qt.point(0.35, 0), Qt.point(0, 0.35), Qt.point(-0.35, 0)]
    label: qsTr("CM")
    symbolScale: 0.45

    stats: Stats {
        durable: 1 // 20 hp: anything that reaches it kills it
        stealth: 0 // stock only — a pop dresses the decoy in its deployer's
    }
}
