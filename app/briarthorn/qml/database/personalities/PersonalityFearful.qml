import ".."

// Keeps its distance: orbits well inside its own envelope with the trigger
// cold, buys one paced shot with two safe seconds, and drops everything the
// moment danger shows. The orbit at 0.8 sits clear of the snipe gate at 0.9
// so the entry holds solidly rather than flickering on the rim.
Personality {
    name: Names.personality.fearful

    switches: [
        SwitchThreat {
            present: true
            within: 0.6
            to: Names.stance.bail
        },
        SwitchAmmoOut {
            to: Names.stance.depart
        }
    ]

    stances: [
        Stance {
            name: Names.stance.shadow
            maneuver: Names.maneuver.evade
            holdFire: true
            standoff: 0.8
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.9
                    dwell: 2
                    to: Names.stance.snipe
                }
            ]
        },
        Stance {
            name: Names.stance.snipe
            maneuver: Names.maneuver.pursue
            holdoff: 8
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.5
                    to: Names.stance.shadow
                },
                SwitchRange {
                    inside: false
                    at: 1
                    dwell: 1
                    to: Names.stance.shadow
                }
            ]
        },
        Stance {
            name: Names.stance.bail
            maneuver: Names.maneuver.notch
            reference: Stance.Reference.Threat
            holdFire: true
            switches: [
                SwitchThreat {
                    present: false
                    within: 0.6
                    dwell: 1.5
                    to: Names.stance.shadow
                }
            ]
        },
        Stance {
            name: Names.stance.depart
            maneuver: Names.maneuver.flee
            holdFire: true
        }
    ]
}
