pragma Singleton

import QtQuick

// The ability registry: one definition row per invocable ability, keyed by
// name — slots reference these rows and defFor() is the router's lookup.
QtObject {
    id: root

    readonly property AbilityFlare flare: AbilityFlare {}

    readonly property AbilityLaunch launchGuided: AbilityLaunch {
        name: "guided"
        label: qsTr("GUIDED")
        cooldown: 2.5
        charges: 6
        weapon: Classification.Kind.MissileGuided
    }

    readonly property AbilityLaunch launchKinetic: AbilityLaunch {
        name: "kinetic"
        label: qsTr("KINETIC")
        cooldown: 2
        charges: 4
        weapon: Classification.Kind.MissileKinetic
    }

    function defFor(name: string): Ability {
        switch (name) {
        case "flare":
            return root.flare;
        case "guided":
            return root.launchGuided;
        case "kinetic":
            return root.launchKinetic;
        default:
            return null;
        }
    }
}
