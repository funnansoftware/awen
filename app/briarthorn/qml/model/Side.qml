import QtQml

// Allegiance of a world object; drives the symbol colour.
QtObject {
    enum Kind {
        Unknown,
        Ownship,
        Friendly,
        Neutral,
        Hostile
    }
}
