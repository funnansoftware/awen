import QtQml

// One blast in progress: recorded by SystemWeapon at detonation and aged
// out. The view expands a ring toward blastRadius as life runs down and
// fades it with the remaining fraction.
QtObject {
    id: root

    property real worldX: 0
    property real worldY: 0
    property real blastRadius: 0
    property real life: 0
    property real maxLife: 1
}
