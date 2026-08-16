import ".."

// Fights one exchange at a time: presses to fire, then cranks — trigger held,
// target ridden at the cone's edge — until the round in flight dies, so no
// magazine ever streams. Beams genuine inbounds early enough to watch, flies
// its flares off once one bites, breaks off dry, and opens a too-close merge
// back out to launch distance rather than wasting a round that cannot make
// its turn — unless the merge has closed inside the gun's envelope, where it
// takes the knife fight instead.
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
                // Inside the gun's envelope the knife fight beats everything
                // offensive, so it outranks the exchange rhythm and the
                // withdraw below.
                SwitchRange {
                    inside: true
                    ability: "gun"
                    to: Names.stance.brawl
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
                SwitchRange {
                    inside: true
                    ability: "gun"
                    to: Names.stance.brawl
                },
                SwitchOutbound {
                    present: false
                    dwell: 0.5
                    to: Names.stance.press
                }
            ]
        },
        // The knife fight: inside the gun's envelope missiles cannot make
        // their turns, so ride the target's tail and hold the gatling down —
        // an automatic trigger needs no holdoff, its own cycle is the rate
        // of fire. Survival still outranks it (an inbound takes the beam),
        // and the target opening back out past the envelope — a shade past,
        // dwelled, so the edge never flaps — resumes the missile exchange.
        Stance {
            name: Names.stance.brawl
            maneuver: Names.maneuver.pursue
            ability: "gun"
            switches: [
                SwitchThreat {
                    present: true
                    within: 0.45
                    dwell: 0.3
                    to: Names.stance.guard
                },
                SwitchRange {
                    inside: false
                    ability: "gun"
                    at: 1.1
                    dwell: 0.75
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
                // A pursuer that runs the extension down to gun range has
                // taken the choice away: turn and fight rather than be shot
                // in the back.
                SwitchRange {
                    inside: true
                    ability: "gun"
                    to: Names.stance.brawl
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
