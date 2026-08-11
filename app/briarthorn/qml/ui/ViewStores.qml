pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Shapes
import awen.shapes
import "../database"
import "../input"
import "../model"
import "../themes"

// The stores page: ownship's plan view with every carried ability's stations
// drawn at their places on the airframe, each wearing the outline of the round
// it holds — green where a press would take,
// caution-coloured where it cannot yet, hollow while a round is in the air,
// muted once spent — the rounds-away tally beneath, and the ability buttons
// seated at the foot, the best reach the right thumb has. State lives in
// colour on the silhouette and quantity on the buttons, so neither says the
// other's line.
Item {
    id: root

    // The flown craft, the caps' keymap, the device driving them, and
    // whether the hand controls draw at all.
    required property Entity ownship
    required property Keymap keymap
    required property ActiveDevice device
    property bool racks: false

    // The rack's press and its touch report, routed by the caller.
    signal invoked(string ability)
    signal touched

    // Rounds in the air across the whole loadout; which rack each came from
    // is the hollow station's job.
    readonly property int awayTotal: {
        let total = 0;
        for (let i = 0; i < root.ownship.abilities.length; ++i)
            total += root.ownship.abilities[i].away;
        return total;
    }

    // The airframe, centred in what the buttons and tally leave: the very
    // symbol the scope plots ownship with, drawn large — so the stores page
    // and the picture can never disagree about what the craft looks like.
    Symbol {
        id: airframe

        readonly property real extent: Math.max(60, Math.min(root.width * 0.7, root.height - buttons.height - away.height - 28))

        symbolSize: airframe.extent
        classification: root.ownship ? root.ownship.classification : Classification.Kind.AircraftFighter
        side: root.ownship ? root.ownship.side : Side.Kind.Ownship
        showLabel: false
        anchors.horizontalCenter: parent.horizontalCenter
        y: 2
    }

    // Every carried ability's stations, drawn over the airframe in the same
    // unit-box frame the silhouette is authored in.
    Repeater {
        model: root.ownship.abilities

        Item {
            id: rack

            required property AbilitySlot modelData

            readonly property var stations: rack.modelData.def ? rack.modelData.def.stations : []

            // What those stations hold, drawn with the very outline the scope
            // plots the round with — so a dart on the wing and the dart it
            // becomes in the air can never look like different things.
            readonly property Data glyph: Database.dataFor(rack.modelData.def ? rack.modelData.def.stationKind : Classification.Kind.Unknown)

            // Stations still loaded: per-round where one station carries one
            // round, a proportional magazine where a pod stands behind fewer
            // stations than charges (the flare dispensers).
            readonly property int lit: {
                const shipped = rack.modelData.def ? rack.modelData.def.charges : 0;
                if (shipped <= 0 || rack.stations.length === 0)
                    return 0;
                return Math.ceil(Math.max(0, rack.modelData.charges) * rack.stations.length / shipped);
            }

            // Stations shown as rounds in the air, after the loaded ones.
            readonly property int away: Math.min(rack.modelData.away, rack.stations.length - rack.lit)

            // The user's colour language: green would take, caution cannot
            // yet, and the refusal beat below overrides both in the error
            // colour.
            readonly property color loadedTint: rack.modelData.valid ? Style.theme.armValid : Style.theme.warn

            // The armed breathing, shared by the slot's whole station group;
            // written only by the animation, never bound over.
            property real breathe: 1

            // The refusal beat, raised by the slot exactly as the rack
            // button's is: three quick pulses in the error colour.
            property real flash: 0

            anchors.fill: airframe

            SequentialAnimation on breathe {
                running: rack.modelData.armed
                loops: Animation.Infinite

                NumberAnimation { from: 1; to: 0.35; duration: 320 }
                NumberAnimation { from: 0.35; to: 1; duration: 320 }
            }

            SequentialAnimation {
                id: refusal

                loops: 3

                NumberAnimation { target: rack; property: "flash"; from: 0; to: 1; duration: 80 }
                NumberAnimation { target: rack; property: "flash"; from: 1; to: 0; duration: 120 }
            }

            Connections {
                target: rack.modelData

                function onRefused() {
                    refusal.restart();
                }
            }

            Repeater {
                model: rack.stations

                ShapePolygon {
                    id: pip

                    required property point modelData
                    required property int index

                    readonly property bool loaded: pip.index < rack.lit
                    readonly property bool flying: !pip.loaded && pip.index < rack.lit + rack.away

                    // The silhouette scales uniformly to the square airframe
                    // item, so a station point maps with the same factor.
                    readonly property real span: Math.min(rack.width, rack.height)

                    // The station's one colour: filled with it on the rail,
                    // hollowed to it in the air. The refusal beat below
                    // overrides both in the error colour.
                    readonly property color tint: {
                        if (refusal.running)
                            return Style.theme.armInvalid;
                        if (pip.flying)
                            return Style.theme.armValid;
                        return pip.loaded ? rack.loadedTint : Qt.alpha(Style.theme.textMuted, 0.35);
                    }

                    points: rack.glyph.outline
                    fillColor: pip.flying ? "transparent" : pip.tint
                    strokeColor: pip.tint
                    strokeWidth: Math.max(1, pip.width * 0.05)
                    // Round joins, as the scope marks use: the missiles' acute
                    // noses exceed the default miter limit and would chop flat.
                    joinStyle: ShapePath.RoundJoin
                    x: rack.width / 2 + pip.modelData.x * pip.span - width / 2
                    y: rack.height / 2 + pip.modelData.y * pip.span - height / 2
                    // Sized off the airframe and then by the kind's own symbol
                    // scale, so a store reads at the size the scope plots it —
                    // and small enough that the cheek pair of kinetic slugs,
                    // seated a tenth of the span apart, stays two rounds.
                    width: Math.max(6, pip.span * 0.16 * rack.glyph.symbolScale)
                    height: width
                    opacity: refusal.running ? 0.4 + 0.6 * rack.flash : (rack.modelData.armed ? rack.breathe : 1)
                }
            }
        }
    }

    // The tally: how many of ownship's rounds are in the air right now.
    Row {
        id: away

        spacing: 8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: airframe.bottom
        anchors.topMargin: 6

        Text {
            text: qsTr("AWAY")
            color: Style.theme.textLabel
            font { pixelSize: 11; letterSpacing: Style.theme.capsTracking; family: Style.monospace }
        }

        Text {
            text: root.awayTotal
            color: root.awayTotal > 0 ? Style.theme.textBright : Style.theme.textMuted
            font { pixelSize: 11; bold: true; family: Style.monospace }
        }
    }

    // The rack, in the corner under the thumb. Same component as the overlay
    // HUD's, so an ability reads the same however the glass is arranged, and
    // the same one every device drives — a thumb presses these buttons rather
    // than a rack of its own.
    ViewAbilities {
        id: buttons

        visible: root.racks
        buttonSize: 64
        // The rack keeps clear of the tile's own legend, and a wide loadout
        // shrinks rather than running out of the frame — down to a thumb's
        // target and no further, since a thumb is one of the things pressing
        // it.
        maximumWidth: root.width - 34
        minimumButtonSize: 44
        keymap: root.keymap
        loadout: root.ownship.abilities
        device: root.device
        onInvoked: ability => root.invoked(ability)
        onTouched: root.touched()

        anchors {
            right: parent.right
            bottom: parent.bottom
        }
    }
}
