import QtQuick
import awen.gamepad
import "../themes"

// One control cap: the player-facing name of a bound key or button, or a dash
// where nothing is bound. A controller cap draws the way the pad does — a
// coloured disc for one of the four face buttons, an accent pill for everything
// else — so the glyph on screen is the one printed under the player's thumb.
// Fixed height and an optional floor under its width, so a row does not reflow
// as the player rebinds it. Shared by the settings page, the hint line and the
// ability buttons, so a control reads the same in all three.
Rectangle {
    id: root

    // What the control is called; empty renders as unbound.
    property string label: ""

    // Whether the control is a controller button, and which one — the code
    // picks the face colour, and only the four faces carry one.
    property bool pad: false
    property int code: -1

    // Waiting for the player to press a control, or having just lost one to
    // another ability.
    property bool waiting: false
    property bool displaced: false

    // The narrowest the cap may draw. The settings page pins a floor under it
    // so a row does not reflow as the player rebinds; an ability button, where
    // the cap is a hint over a caption, lets it shrink to its text.
    property real minimumWidth: 64

    // Text size, and with it the cap's height: a cap riding a small button
    // scales down with it rather than crowding the caption underneath.
    property real fontSize: 12

    readonly property bool bound: root.label !== ""

    // Canonical controller colours for the four face buttons, fixed across
    // themes: these are the colours printed on the pad in the player's hands,
    // muscle memory rather than app chrome.
    readonly property var faceColors: ({
            [Gamepad.Button.South]: "#FF5BB94B",
            [Gamepad.Button.East]: "#FFD94B4B",
            [Gamepad.Button.West]: "#FF3E78D0",
            [Gamepad.Button.North]: "#FFE6B23E"
        })

    // Whether this cap draws as a face button, and in what colour.
    readonly property bool face: root.pad && root.bound && !root.waiting && root.faceColors[root.code] !== undefined
    readonly property color faceColor: root.face ? root.faceColors[root.code] : "transparent"

    // One tint carries the state: bright while capturing, warn just after
    // another ability took this control away, plain otherwise.
    readonly property color tint: {
        if (root.waiting)
            return Style.theme.accentBright;
        if (root.displaced)
            return Style.theme.warn;
        return root.bound ? Style.theme.textPrimary : Style.theme.textMuted;
    }

    // The cap keeps its text-cap footprint even when it draws as a disc, so a
    // column of them lines up whatever each row happens to be bound to.
    implicitWidth: Math.max(root.minimumWidth, caption.implicitWidth + 14)
    implicitHeight: Math.round(root.fontSize * 1.85)
    radius: Style.theme.panelRadius
    color: root.face || !root.bound ? "transparent" : Style.theme.instrumentBackground
    border.width: root.face ? 0 : 1
    // A pad pill takes the accent, so a controller binding never reads as a
    // key cap.
    border.color: {
        if (root.waiting || root.displaced)
            return root.tint;
        if (root.pad && root.bound)
            return Style.theme.accent;
        return root.bound ? Style.theme.frameInner : Style.theme.textMuted;
    }

    // The face button itself, sitting in the cap's footprint rather than
    // replacing it.
    Rectangle {
        anchors.centerIn: parent
        visible: root.face
        width: root.height
        height: width
        radius: width / 2
        color: root.faceColor
    }

    Text {
        id: caption

        anchors.centerIn: parent
        text: root.waiting ? qsTr("PRESS…") : (root.bound ? root.label : "—")
        // The face colours are bright, so their glyph is punched out dark
        // rather than tinted with the rest of the chrome.
        color: root.face ? "#FF0B141B" : root.tint
        font { pixelSize: root.fontSize; bold: true; family: Style.monospace }
    }
}
