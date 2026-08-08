import ".."

// Fights one exchange at a time: presses to fire, then cranks — trigger held,
// target ridden at the cone's edge — until the round in flight dies, so no
// magazine ever streams. Beams genuine inbounds early enough to watch, flies
// its flares off once one bites, breaks off dry, and opens a too-close merge
// back out to launch distance rather than wasting a round that cannot make
// its turn.
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
                },
                // A launch from inside ~half the round's reach cannot make
                // its turn; no dwell, so the crossing tick holds fire before
                // the trigger system runs.
                SwitchRange {
                    inside: true
                    at: 0.55
                    to: Names.stance.withdraw
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
        // Guard holds the trigger too: a notch that sweeps the cone across
        // the target would otherwise stream rounds — at whatever range the
        // fight has closed to — outside the press-crank exchange rhythm.
        Stance {
            name: Names.stance.guard
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
                    within: 0.45
                    dwell: 0.5
                    to: Names.stance.press
                }
            ]
        },
        // Selling the flare: the decoy wears the same return as the craft, so
        // the seeker keeps whichever it is nearer to — beaming from here
        // would only walk the craft back into that comparison. Run dead away
        // from the decoy, cold, until the round is off it; a fresh inbound is
        // worth more than an old flare and takes the stance back.
        Stance {
            name: Names.stance.defeat
            maneuver: Names.maneuver.flee
            reference: Stance.Reference.Decoy
            holdFire: true
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.45
                    dwell: 0.3
                    to: Names.stance.guard
                },
                SwitchDecoy {
                    present: false
                    to: Names.stance.press
                }
            ]
        },
        // The extension: run dead away — trigger cold — and press again once
        // comfortably clear of the failure band. Flee, not evade: evade
        // trades radial speed for perimeter riding as it nears its ring, and
        // a merely-jogging pursuer stalls that inside the rejoin edge forever.
        Stance {
            name: Names.stance.withdraw
            maneuver: Names.maneuver.flee
            holdFire: true
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.45
                    dwell: 0.3
                    to: Names.stance.guard
                },
                SwitchRange {
                    inside: false
                    at: 0.8
                    dwell: 1
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
