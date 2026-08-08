import ".."

// Denial, not sniping: it holds station just outside the TARGET's envelope,
// fires only at an intruder who presses into it, and half a hull ends its
// war — where fearful trusts distance and has no health response at all.
// Against an unarmed target the range switches never fire and monitor's
// standoff falls back to the carrier's own reach.
Personality {
    name: Names.personality.defensive

    switches: [
        SwitchThreat {
            present: true
            within: 1
            to: Names.stance.defend
        },
        SwitchHealth {
            below: 0.5
            to: Names.stance.abscond
        },
        SwitchAmmoOut {
            to: Names.stance.abscond
        }
    ]

    stances: [
        Stance {
            name: Names.stance.monitor
            maneuver: Names.maneuver.evade
            holdFire: true
            standoff: 1.15
            standoffOf: Envelope.Kind.TargetWeapon
            switches: [
                SwitchRange {
                    inside: true
                    at: 0.9
                    of: Envelope.Kind.TargetWeapon
                    dwell: 1
                    to: Names.stance.repel
                }
            ]
        },
        Stance {
            name: Names.stance.repel
            maneuver: Names.maneuver.pursue
            holdoff: 4
            switches: [
                SwitchRange {
                    inside: false
                    at: 1
                    of: Envelope.Kind.TargetWeapon
                    dwell: 2
                    to: Names.stance.monitor
                }
            ]
        },
        Stance {
            name: Names.stance.defend
            maneuver: Names.maneuver.notch
            reference: Stance.Reference.Threat
            holdFire: true
            switches: [
                SwitchDecoy {
                    present: true
                    to: Names.stance.defeat
                },
                SwitchThreat {
                    present: false
                    within: 1
                    dwell: 3
                    to: Names.stance.monitor
                }
            ]
        },
        // Working the flare it just popped: a decoy carries the same return
        // as the craft, so the round stays on it only while the craft opens
        // the range. Run dead away from the decoy, cold, and back to station
        // once the round is off it — a fresh inbound is the personality's
        // own switch to make, above.
        Stance {
            name: Names.stance.defeat
            maneuver: Names.maneuver.flee
            reference: Stance.Reference.Decoy
            holdFire: true
            switches: [
                SwitchDecoy {
                    present: false
                    to: Names.stance.monitor
                }
            ]
        },
        Stance {
            name: Names.stance.abscond
            maneuver: Names.maneuver.flee
            holdFire: true
        }
    ]
}
