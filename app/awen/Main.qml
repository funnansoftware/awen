import QtQuick
import awen.entity

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

    Canvas {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height

        onPaint: {
            var ctx = getContext("2d");
            var centerX = width / 2;
            var centerY = height / 2;
            var radius = height * 0.4;
            var startAngle = (30 - 90) * Math.PI / 180;
            var endAngle = (30 + 10 - 90) * Math.PI / 180;

            ctx.strokeStyle = "white";
            ctx.lineWidth = 3;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, startAngle, endAngle + Math.PI * 2 - 20 * Math.PI / 180, false);
            ctx.stroke();
        }
    }
}
