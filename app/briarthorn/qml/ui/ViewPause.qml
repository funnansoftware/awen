import QtQuick

// The pause menu (Escape / pad Start mid-duel), over the frozen scope and
// HUD. Resume leads and restart sits with it — a duel flown into a bad
// opening is abandoned far more often than it is quit — with the way back to
// the launch screen and out of the game below them. Ports briardart's
// PauseOverlay.
MenuPage {
    id: root

    signal resumed
    signal restarted
    signal settingsRequested
    signal toMenu
    signal exitGame

    title: qsTr("PAUSED")
    dismissible: true
    onDismissed: root.resumed()

    // The web build has no window of its own to close, so it carries no exit.
    entries: {
        const list = [
            {
                label: qsTr("RESUME"),
                primary: true,
                act: () => root.resumed()
            },
            {
                label: qsTr("RESTART"),
                primary: false,
                act: () => root.restarted()
            },
            {
                label: qsTr("SETTINGS"),
                primary: false,
                act: () => root.settingsRequested()
            },
            {
                label: qsTr("MAIN MENU"),
                primary: false,
                act: () => root.toMenu()
            }
        ];
        if (Qt.platform.os !== "wasm") {
            list.push({
                label: qsTr("EXIT GAME"),
                primary: false,
                act: () => root.exitGame()
            });
        }
        return list;
    }
}
