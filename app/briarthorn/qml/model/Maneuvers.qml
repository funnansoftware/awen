pragma Singleton

import QtQml

// The maneuver factory registry: database stances name flights by string so
// the database keeps importing nothing back, and this table turns a name
// into a live instance. A new maneuver is its model file plus one Component
// and one table line here.
QtObject {
    id: root

    readonly property Component pursue: Component {
        ManeuverPursue {}
    }

    readonly property Component evade: Component {
        ManeuverEvade {}
    }

    readonly property Component notch: Component {
        ManeuverNotch {}
    }

    readonly property Component orbit: Component {
        ManeuverOrbit {}
    }

    readonly property Component flee: Component {
        ManeuverFlee {}
    }

    readonly property Component formation: Component {
        ManeuverFormation {}
    }

    readonly property var table: ({
            "pursue": root.pursue,
            "evade": root.evade,
            "notch": root.notch,
            "orbit": root.orbit,
            "flee": root.flee,
            "formation": root.formation
        })

    // A fresh maneuver of the named kind under the given owner, or null with
    // a warning for a name nothing registered.
    function make(name: string, owner: QtObject): Maneuver {
        const factory = root.table[name];
        if (factory === undefined) {
            console.warn("Maneuvers: no registered maneuver named \"" + name + "\"");
            return null;
        }
        return factory.createObject(owner) as Maneuver;
    }
}
