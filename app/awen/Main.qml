import QtQuick
import awen.entity
import awen.shapes

Window {
    id: window
    width: 1280
    height: 720
    visible: true
    title: "Awen"
    color: '#ff274b6a'

    property list<entity> entities: [
        {
            name: "Entity 1",
            x: 100,
            y: 100,
            heading: 45
        },
        {
            name: "Entity 2",
            x: 200,
            y: 150,
            heading: 90
        },
        {
            name: "Entity 3",
            x: 300,
            y: 200,
            heading: 135
        }
    ]

    Component.onCompleted: {
        console.log("Entity:", entities);
    }

    Repeater {
        id: repeater
        model: window.entities
        delegate: Item {
            id: item
            required property entity modelData

            width: 64
            height: 64
            x: modelData.x
            y: modelData.y

            Rectangle {
                anchors.fill: parent
                color: "red"
                rotation: item.modelData.heading
            }
        }
    }

    // The range-ring pattern: a gapped ring with the app's label anchored on
    // the exposed gapCenter readout.
    ShapeRing {
        id: ring
        anchors.fill: parent
        radius: parent.height * 0.4
        gapAngle: 25
        gapLength: 50
        strokeColor: "white"
        strokeWidth: 3

        Text {
            x: ring.gapCenter.x - width / 2
            y: ring.gapCenter.y - height / 2
            text: "40"
            color: "white"
            font.bold: true
        }
    }

    // A gauge cycling its fill, as a living ShapeGauge example.
    ShapeGauge {
        width: 96
        height: 96
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: 24
        fillColor: "#ffa100"

        SequentialAnimation on value {
            loops: Animation.Infinite
            NumberAnimation { from: 0; to: 1; duration: 2000; easing.type: Easing.InOutQuad }
            NumberAnimation { from: 1; to: 0; duration: 2000; easing.type: Easing.InOutQuad }
        }
    }

    // The synthetic scope stress page; S toggles it over the sample scene.
    StressScope {
        id: stress
        anchors.fill: parent
        visible: false
    }

    Shortcut {
        sequence: "S"
        onActivated: stress.visible = !stress.visible
    }
}
