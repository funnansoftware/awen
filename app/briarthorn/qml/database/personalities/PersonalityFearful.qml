import ".."

// Keeps its distance: orbits well inside its own envelope with the trigger
// cold, buys one paced shot with two safe seconds, and drops everything the
// moment danger shows. The orbit at 0.8 sits clear of the snipe gate at 0.9
// so the entry holds solidly rather than flickering on the rim.
Personality {
    name: "fearful"

    switches: [
        SwitchThreat {
            present: true
            within: 0.6
            to: "bail"
        },
        SwitchAmmoOut {
            to: "depart"
        }
    ]

    stances: [
        Stance {
            name: "shadow"
            maneuver: "evade"
            holdFire: true
            standoff: 0.8
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.9
                    dwell: 2
                    to: "snipe"
                }
            ]
        },
        Stance {
            name: "snipe"
            maneuver: "pursue"
            holdoff: 8
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.5
                    to: "shadow"
                },
                SwitchRange {
                    inside: false
                    at: 1
                    dwell: 1
                    to: "shadow"
                }
            ]
        },
        Stance {
            name: "bail"
            maneuver: "notch"
            reference: Stance.Reference.Threat
            holdFire: true
            switches: [
                SwitchThreat {
                    present: false
                    within: 0.6
                    dwell: 1.5
                    to: "shadow"
                }
            ]
        },
        Stance {
            name: "depart"
            maneuver: "flee"
            holdFire: true
        }
    ]
}
