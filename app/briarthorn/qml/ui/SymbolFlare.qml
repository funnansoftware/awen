import QtQuick
import "../themes"

// A deployed countermeasure flare on the scope: briardart's burning radar
// lure (scope_component._drawFlare) reduced to its quiet form — a steady hot
// gold point source with a faint glow, inside a single expanding, fading
// heat ring. Side-agnostic: burning magnesium reads the same whoever dropped
// it. Centre it on the plot point like Symbol.
Item {
    id: symbol

    // Symbol size in px before the flare's own scale; the heat ring swells
    // to roughly this footprint.
    property real symbolSize: 36

    width: symbolSize * 0.9
    height: width

    // The heat ring: born at the core, swelling to the rim and fading out.
    Rectangle {
        id: ring
        anchors.centerIn: parent
        width: parent.width
        height: width
        radius: width / 2
        color: "transparent"
        border.color: Style.theme.warn
        border.width: Math.max(1.5, symbol.width * 0.045)

        SequentialAnimation {
            running: symbol.visible
            loops: Animation.Infinite

            ParallelAnimation {
                NumberAnimation {
                    target: ring
                    property: "scale"
                    from: 0.3
                    to: 1
                    duration: 900
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: ring
                    property: "opacity"
                    from: 0.9
                    to: 0
                    duration: 900
                    easing.type: Easing.OutQuad
                }
            }
            PauseAnimation {
                duration: 150
            }
        }
    }

    // A soft standing glow seating the core on the dark scope.
    Rectangle {
        anchors.centerIn: parent
        width: symbol.width * 0.5
        height: width
        radius: width / 2
        color: Style.theme.flare
        opacity: 0.18
    }

    // The hot core, burning with a fast subtle flicker.
    Rectangle {
        id: core
        anchors.centerIn: parent
        width: symbol.width * 0.24
        height: width
        radius: width / 2
        color: Style.theme.flare

        SequentialAnimation on opacity {
            running: symbol.visible
            loops: Animation.Infinite

            NumberAnimation {
                from: 1
                to: 0.75
                duration: 200
            }
            NumberAnimation {
                from: 0.75
                to: 1
                duration: 200
            }
        }
    }
}
