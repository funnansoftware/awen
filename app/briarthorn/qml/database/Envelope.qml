import QtQml

// The spans a personality prices its distances against, so a definition
// never spells a metre: the carrier's own weapon reach, the target's, or the
// carrier's detection range.
QtObject {
    enum Kind {
        OwnWeapon,
        TargetWeapon,
        Detection
    }
}
