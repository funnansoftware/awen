import QtQuick
import "../themes"

// The full-width top status band: a themed strip across the top edge carrying
// persistent meta-game readouts — the credit purse now, with room for more — on
// the left, and the build version and the settings button on the right. The
// corner instruments sit below it. Distinct from ViewStatus (the ownship's
// hull/fuel condition): this band is campaign/meta state. Ports briardart's
// TopStatusBar (ui/panels/top_status_bar).
//
// The caller sizes the band off the window, as it sizes the corner instruments;
// everything drawn inside is a multiple of that height, so the strip reads as
// one piece at any size rather than as fixed type stranded in a growing gap.
Rectangle {
    id: root

    // Persistent readouts.
    property int credits: 0
    property string version: ""

    // The settings button, pressed. The bar knows nothing of what settings are
    // or when they may be opened; Main owns both.
    signal settingsRequested

    // Every size below is the value the band shipped with times this, and 44 is
    // the height those values were drawn for — so the band at its floor is the
    // strip as designed, and a taller one scales whole rather than in pieces.
    readonly property real uiScale: root.height / 44

    // The floor, and the standalone size: the caller normally binds height.
    implicitHeight: 44
    color: Style.theme.panelBackground

    // A hairline along the bottom edge separates the band from the scope below.
    // A hairline at any size, so it does not scale.
    Rectangle {
        height: 1
        color: Style.theme.frameInner
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
    }

    // Persistent readouts, left-aligned. Add more as another Stat (with a
    // Divider woven between) — e.g. Stat { label: "LVL"; value: level }.
    Row {
        id: stats

        spacing: 10 * root.uiScale
        anchors { left: parent.left; leftMargin: 16 * root.uiScale; verticalCenter: parent.verticalCenter }

        Stat {
            uiScale: root.uiScale
            value: root.credits.toLocaleString(Qt.locale(), 'f', 0)
            unit: qsTr("CR")
        }
    }

    // The way into the settings page from the game itself — the pause menu is
    // the other one. A cap-shaped face carrying three fader rails, drawn rather
    // than set in type: the gear character is missing from the instrument face
    // on windows, and what the font machinery substitutes for it is a different
    // drawing on every platform.
    Rectangle {
        id: settingsButton

        readonly property color tint: hit.containsMouse ? Style.theme.accentBright : Style.theme.accent

        width: 24 * root.uiScale
        height: width
        radius: Style.theme.panelRadius
        color: hit.containsMouse ? Qt.alpha(Style.theme.accent, 0.2) : Style.theme.instrumentBackground
        border.width: 1
        border.color: hit.containsMouse ? Style.theme.accentBright : Style.theme.frameInner
        anchors { right: parent.right; rightMargin: 16 * root.uiScale; verticalCenter: parent.verticalCenter }

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }
        Behavior on border.color {
            ColorAnimation {
                duration: 120
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 4 * root.uiScale

            Rail {
                seat: 0.72
                tint: settingsButton.tint
                uiScale: root.uiScale
            }
            Rail {
                seat: 0.28
                tint: settingsButton.tint
                uiScale: root.uiScale
            }
            Rail {
                seat: 0.62
                tint: settingsButton.tint
                uiScale: root.uiScale
            }
        }
    }

    // The build version, right-aligned and dim, pushed left by the button. It
    // elides rather than growing into the readouts: this bar is meant to take
    // more stats, and two texts meeting in the middle is the failure that
    // invites.
    Text {
        text: root.version
        color: Style.theme.textMuted
        elide: Text.ElideRight
        horizontalAlignment: Text.AlignRight
        width: Math.max(0, settingsButton.x - (stats.x + stats.width) - 24 * root.uiScale)
        font { pixelSize: 12 * root.uiScale; family: Style.monospace }
        anchors { right: settingsButton.left; rightMargin: 12 * root.uiScale; verticalCenter: parent.verticalCenter }
    }

    // The button's hit target, a sibling of the face rather than a child of it:
    // the face is well under a thumb, so the target takes the whole height of
    // the band — growing with it, instead of being pinned to the face and
    // staying one size whenever the band changes — and reaches out past it on
    // both sides. The reach into the clear gap below does NOT scale: the
    // minimap sits 12px under the band whatever size it is.
    MouseArea {
        id: hit

        width: settingsButton.width + 20 * root.uiScale
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.settingsRequested()
        anchors {
            // 10 wider than the face on each side, so it sits 10 in from where
            // the face sits and stays centred on it.
            right: parent.right
            rightMargin: 6 * root.uiScale
            top: parent.top
            bottom: parent.bottom
            bottomMargin: -8
        }
    }

    // One readout chip: an optional dim label, the bright value, and an optional
    // dim unit (e.g. CR). The shared building block for every stat.
    //
    // The band's scale is handed in rather than read off root: an inline
    // component is its own component, so the enclosing file's ids are not in
    // its scope.
    component Stat: Row {
        id: stat

        property string label: ""
        property string value: ""
        property string unit: ""
        property real uiScale: 1

        spacing: 4 * stat.uiScale

        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: stat.label
            color: Style.theme.textLabel
            font { pixelSize: 10 * stat.uiScale; bold: true; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: stat.value
            color: Style.theme.textPrimary
            font { pixelSize: 15 * stat.uiScale; bold: true; family: Style.monospace }
        }

        Text {
            visible: text !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: stat.unit
            color: Style.theme.textLabel
            font { pixelSize: 10 * stat.uiScale; bold: true; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }
    }

    // A thin vertical divider to weave between successive stats.
    component Divider: Rectangle {
        id: divider

        property real uiScale: 1

        anchors.verticalCenter: parent.verticalCenter
        width: 1
        height: 16 * divider.uiScale
        color: Style.theme.frameInner
    }

    // One fader rail with its handle seated along it; three of them stacked make
    // the settings glyph, in the same rails-and-bugs vocabulary the instruments
    // are drawn in.
    component Rail: Rectangle {
        id: rail

        // Where the handle sits along the rail, 0 at the left end.
        property real seat: 0.5
        property color tint: Style.theme.accent
        property real uiScale: 1

        width: 14 * rail.uiScale
        height: 2 * rail.uiScale
        radius: height / 2
        color: Qt.alpha(rail.tint, 0.5)

        Behavior on color {
            ColorAnimation {
                duration: 120
            }
        }

        Rectangle {
            x: (rail.width - width) * rail.seat
            anchors.verticalCenter: parent.verticalCenter
            width: 4 * rail.uiScale
            height: width
            radius: 1
            color: rail.tint

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }
    }
}
