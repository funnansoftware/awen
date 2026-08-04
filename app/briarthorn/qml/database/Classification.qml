import QtQml

// Enumerates what a world object is — the key every definition row hangs off
// and the one the Database indexes by. Append new kinds immediately before
// Count and never reorder, so the numeric values stay stable for anything that
// persists one.
QtObject {
    id: root

    enum Kind {
        Unknown,
        AircraftFighter,
        MissileGuided,
        MissileKinetic,
        Decoy,
        AircraftFighterLight,
        Count
    }
}
