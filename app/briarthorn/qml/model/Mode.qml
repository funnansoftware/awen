import QtQml

// Which screen the shell is showing, and so which one holds the input: the
// launch screen, the duel under the player's hands, the pause menu over a
// frozen duel, the decided duel's result, or the settings page standing over
// one of the others. One value rather than a set of flags, so the states the
// flags admitted but the game has no meaning for — a pause menu over the
// launch screen, a settings page over a running duel — cannot be spelled at
// all, rather than being kept out by every transition remembering to clear a
// flag it is not otherwise about.
QtObject {
    id: root

    enum Kind {
        Menu,
        Duel,
        Pause,
        End,
        Settings
    }
}
