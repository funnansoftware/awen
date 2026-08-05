import ".."

// Attrition: cycles a firing band on its own envelope — advance cold, strike
// paced, withdraw when pressed — with overlapped band edges as hysteresis,
// notches only genuine inbounds, and retires hurt or dry.
Personality {
    name: "tactical"

    switches: [
        SwitchThreat {
            present: true
            within: 0.4
            to: "evade"
        },
        // Hurt is one solid hit: flat warhead damage quantizes the hull, so
        // a deeper threshold would never be seen alive.
        SwitchHealth {
            below: 0.45
            to: "retire"
        },
        SwitchAmmoOut {
            to: "retire"
        }
    ]

    stances: [
        Stance {
            name: "advance"
            maneuver: "pursue"
            holdFire: true
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.9
                    to: "strike"
                }
            ]
        },
        Stance {
            name: "strike"
            maneuver: "pursue"
            holdoff: 10
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.6
                    to: "withdraw"
                },
                SwitchRange {
                    inside: false
                    at: 1
                    dwell: 1
                    to: "advance"
                }
            ]
        },
        Stance {
            name: "withdraw"
            maneuver: "evade"
            holdFire: true
            standoff: 0.9
            switches: [
                SwitchRange {
                    inside: false
                    at: 0.85
                    dwell: 1.5
                    to: "strike"
                }
            ]
        },
        Stance {
            name: "evade"
            maneuver: "notch"
            reference: Stance.Reference.Threat
            holdFire: true
            switches: [
                SwitchThreat {
                    present: false
                    within: 0.4
                    dwell: 1
                    to: "advance"
                }
            ]
        },
        Stance {
            name: "retire"
            maneuver: "flee"
            holdFire: true
        }
    ]
}
