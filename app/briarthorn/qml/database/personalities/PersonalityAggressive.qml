import ".."

// Closes and kills: presses through anything but a terminal inbound, and
// backs off only once staying engaged stops paying — an empty rack. guard
// keeps the trigger; the radar cone is what disciplines a beaming shot.
Personality {
    name: Names.personality.aggressive

    switches: [
        SwitchAmmoOut {
            to: Names.stance.disengage
        }
    ]

    stances: [
        Stance {
            name: Names.stance.press
            maneuver: Names.maneuver.pursue
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.2
                    dwell: 0.3
                    to: Names.stance.guard
                }
            ]
        },
        Stance {
            name: Names.stance.guard
            maneuver: Names.maneuver.notch
            reference: Stance.Reference.Threat
            switches: [
                SwitchDecoy {
                    present: true
                    to: Names.stance.defeat
                },
                SwitchThreat {
                    present: false
                    within: 0.2
                    dwell: 0.5
                    to: Names.stance.press
                }
            ]
        },
        // The pop taking is a maneuver, not a result: the seeker holds
        // whichever of craft and flare it is nearer, so run dead away from
        // the decoy for as long as it carries the round. A fresh inbound
        // outranks an old flare; anything else is back to pressing.
        Stance {
            name: Names.stance.defeat
            maneuver: Names.maneuver.flee
            reference: Stance.Reference.Decoy
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.2
                    dwell: 0.3
                    to: Names.stance.guard
                },
                SwitchDecoy {
                    present: false
                    to: Names.stance.press
                }
            ]
        },
        Stance {
            name: Names.stance.disengage
            maneuver: Names.maneuver.flee
            holdFire: true
        }
    ]
}
