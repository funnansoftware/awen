import QtQml

// The munition role state carried by a missile entity: its definition row,
// seeker lock and the fuze state machine SystemWeapon drives. Non-null only
// on entities that are missiles; the launcher lives on Entity.owner.
QtObject {
    enum State {
        Flying,
        Fuzing
    }

    // The weapon row this round was spawned from.
    property DataWeapon def: null

    // The seeker's current lock; null on kinetic rounds and while no return
    // is illuminated.
    property Entity target: null

    property int state: Weapon.State.Flying

    // Seconds since launch; reaching the definition's duration forces the
    // fuze (self-destruct).
    property real elapsed: 0

    // The entity the fuze tripped on and the seconds since it tripped; the
    // view draws the fuzing line to fuzeTarget. Null on a timeout fuze.
    property Entity fuzeTarget: null
    property real fuzeElapsed: 0
}
