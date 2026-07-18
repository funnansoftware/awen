import QtQuick

// Runs a list of systems against game state: each frame, every enabled
// system's update() is called in declaration order with the frame time in
// seconds. Set running to false and call tick() to step manually.
QtObject {
    id: root

    // The systems to run, in run order; child System objects land here.
    default property list<System> systems

    // Whether the per-frame loop is active.
    property bool running: true

    // One update pass: forwards dt (seconds) to every enabled system.
    function tick(dt: real) {
        for (let i = 0; i < root.systems.length; ++i) {
            const system = root.systems[i];
            if (system.enabled)
                system.update(dt);
        }
    }

    // The frame clock driving the loop, in sync with scene rendering.
    readonly property FrameAnimation clock: FrameAnimation {
        running: root.running
        onTriggered: root.tick(frameTime)
    }
}
