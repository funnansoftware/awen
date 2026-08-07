import QtQml

// One piece of arena geometry: an impassable pillar, a disc in world metres.
// Pure state — SystemCollision wrecks entities on it, the radar systems lose
// line of sight behind it and the scope draws it as terrain.
QtObject {
    id: root

    // Centre in world metres (1 px = 1 m, +x east, +y south).
    property real posX: 0
    property real posY: 0

    // The disc's radius, metres.
    property real radius: 1000
}
