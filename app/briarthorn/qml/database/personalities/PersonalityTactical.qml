import ".."

// Attrition: cycles a firing band on its own envelope — advance cold, strike
// paced, withdraw when pressed — with overlapped band edges as hysteresis,
// notches only genuine inbounds, and retires hurt or dry.
Personality {
    name: Names.personality.tactical

    switches: [
        SwitchThreat {
            present: true
            within: 0.4
            to: Names.stance.evade
        },
        // Hurt is one solid hit: flat warhead damage quantizes the hull, so
        // a deeper threshold would never be seen alive.
        SwitchHealth {
            below: 0.45
            to: Names.stance.retire
        },
        SwitchAmmoOut {
            to: Names.stance.retire
        }
    ]

    stances: [
        Stance {
            name: Names.stance.advance
            maneuver: Names.maneuver.pursue
            holdFire: true
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.9
                    to: Names.stance.strike
                }
            ]
        },
        Stance {
            name: Names.stance.strike
            maneuver: Names.maneuver.pursue
            holdoff: 10
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.6
                    to: Names.stance.withdraw
                },
                SwitchRange {
                    inside: false
                    at: 1
                    dwell: 1
                    to: Names.stance.advance
                }
            ]
        },
        // Withdraw reopens the band dead away — flee, not evade: evade
        // trades radial speed for perimeter riding as it nears its ring, and
        // a merely-jogging pursuer stalls that inside the rejoin edge forever.
        Stance {
            name: Names.stance.withdraw
            maneuver: Names.maneuver.flee
            holdFire: true
            switches: [
                SwitchRange {
                    inside: false
                    at: 0.85
                    dwell: 1.5
                    to: Names.stance.strike
                }
            ]
        },
        Stance {
            name: Names.stance.evade
            maneuver: Names.maneuver.notch
            reference: Stance.Reference.Threat
            holdFire: true
            switches: [
                SwitchThreat {
                    present: false
                    within: 0.4
                    dwell: 1
                    to: Names.stance.advance
                }
            ]
        },
        Stance {
            name: Names.stance.retire
            maneuver: Names.maneuver.flee
            holdFire: true
        }
    ]
}
