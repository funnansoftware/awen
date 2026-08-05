import ".."

// Closes and kills: presses through anything but a terminal inbound, and
// backs off only once staying engaged stops paying — an empty rack. guard
// keeps the trigger; the radar cone is what disciplines a beaming shot.
Personality {
    name: "aggressive"

    switches: [
        SwitchAmmoOut {
            to: "disengage"
        }
    ]

    stances: [
        Stance {
            name: "press"
            maneuver: "pursue"
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.2
                    dwell: 0.3
                    to: "guard"
                }
            ]
        },
        Stance {
            name: "guard"
            maneuver: "notch"
            reference: Stance.Reference.Threat
            switches: [
                SwitchThreat {
                    present: false
                    within: 0.2
                    dwell: 0.5
                    to: "press"
                }
            ]
        },
        Stance {
            name: "disengage"
            maneuver: "flee"
            holdFire: true
        }
    ]
}
