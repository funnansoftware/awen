// Launches one weapon round: guided at the invoker's loudest illuminated
// return, unguided straight off the nose. SystemWeapon consumes the raised
// intent and spawns the missile from the weapon kind named here.
Ability {
    id: root

    // The weapon kind a launch spawns.
    property int weapon: Classification.Kind.Unknown

    stationKind: root.weapon
}
