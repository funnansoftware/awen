import QtQml

// Enumerates what a world object is — the key every per-kind Data row hangs
// off. Append new kinds immediately before Count and never reorder, so the
// numeric values stay stable for anything that persists one.
QtObject {
    enum Kind {
        Unknown,
        AircraftFighter,
        Count
    }
}
