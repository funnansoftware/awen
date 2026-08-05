import ".."

// Denial, not sniping: it holds station just outside the TARGET's envelope,
// fires only at an intruder who presses into it, and half a hull ends its
// war — where fearful trusts distance and has no health response at all.
// Against an unarmed target the range switches never fire and monitor's
// standoff falls back to the carrier's own reach.
Personality {
    name: "defensive"

    switches: [
        SwitchThreat {
            present: true
            within: 1
            to: "break"
        },
        SwitchHealth {
            below: 0.5
            to: "abscond"
        },
        SwitchAmmoOut {
            to: "abscond"
        }
    ]

    stances: [
        Stance {
            name: "monitor"
            maneuver: "evade"
            holdFire: true
            standoff: 1.15
            standoffOf: Envelope.Kind.TargetWeapon
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.9
                    of: Envelope.Kind.TargetWeapon
                    dwell: 1
                    to: "repel"
                }
            ]
        },
        Stance {
            name: "repel"
            maneuver: "pursue"
            holdoff: 4
            switches: [
                SwitchRange {
                    inside: false
                    at: 1
                    of: Envelope.Kind.TargetWeapon
                    dwell: 2
                    to: "monitor"
                }
            ]
        },
        Stance {
            name: "break"
            maneuver: "notch"
            reference: Stance.Reference.Threat
            holdFire: true
            switches: [
                SwitchThreat {
                    present: false
                    within: 1
                    dwell: 3
                    to: "monitor"
                }
            ]
        },
        Stance {
            name: "abscond"
            maneuver: "flee"
            holdFire: true
        }
    ]
}
