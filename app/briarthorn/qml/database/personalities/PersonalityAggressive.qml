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
                SwitchThreat {
                    present: false
                    within: 0.2
                    dwell: 0.5
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
