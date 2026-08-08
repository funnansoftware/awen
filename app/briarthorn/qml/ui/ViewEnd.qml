import QtQuick
import "../systems"
import "../themes"

// The duel's result screen, over the frozen last frame: VICTORY or DEFEAT
// with what decided it, then the retry, the way back to the launch screen
// and the way out. A loss leads with the retry. Ports briardart's EndOverlay.
MenuPage {
    id: root

    // The latched outcome this screen reads.
    required property SystemMission mission

    readonly property bool won: root.mission.status === SystemMission.Status.Victory

    signal flyAgain
    signal toMenu
    signal exitGame

    title: root.won ? qsTr("VICTORY") : qsTr("DEFEAT")
    titleColor: root.won ? Style.theme.accentBright : Style.theme.warn
    subtitle: root.won ? qsTr("%1 DESTROYED").arg(root.mission.target.callsign) : qsTr("AIRCRAFT DESTROYED")

    // The web build has no window of its own to close, so it carries no exit.
    entries: {
        const list = [
            {
                label: qsTr("FLY AGAIN"),
                primary: true,
                act: () => root.flyAgain()
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
