import ".."

// Fights one exchange at a time: presses to fire, then cranks — trigger held,
// target ridden at the cone's edge — until the round in flight dies, so no
// magazine ever streams. Beams genuine inbounds early enough to watch, and
// breaks off dry.
Personality {
    name: Names.personality.duelist

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
                    within: 0.45
                    dwell: 0.3
                    to: Names.stance.guard
                },
                SwitchOutbound {
                    present: true
                    to: Names.stance.crank
                }
            ]
        },
        Stance {
            name: Names.stance.crank
            maneuver: Names.maneuver.crank
            holdFire: true
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.45
                    dwell: 0.3
                    to: Names.stance.guard
                },
                SwitchOutbound {
                    present: false
                    dwell: 0.5
                    to: Names.stance.press
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
                    within: 0.45
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
