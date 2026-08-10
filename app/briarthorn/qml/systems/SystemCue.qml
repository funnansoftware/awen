import awen.entity
import "../audio"
import "../model"

// The duel's voice: watches ownship for the four moments worth hearing and
// sounds one cue each — a round leaving the rail, a seeker taking a return, a
// homing round marked inbound, and the hull taking a hit.
//
// The only system that writes nothing. It reads state rather than being called
// from the systems that cause these moments, because those are simulation and
// this is presentation, and a launch that sounded from inside SystemWeapon
// would sound for every craft in the sky rather than for the one the player is
// sitting in.
//
// Riding the tick rather than bindings is what makes it silent in the right
// places for free: the runner stops with the sim, so a paused fight and a
// decided one say nothing, and the shell leaves it disabled on the launch
// screen so the demo dogfight plays mute behind the menu.
//
// Runs last in the order, so every cue speaks for the tick that has just
// finished rather than the one before it.
System {
    id: root

    // The craft the cues speak for.
    property Entity ownship: null

    // Last tick's readings, so each cue fires on the edge and not the level.
    // Only a fall sounds: a factory-fresh craft restores the hull and refills
    // the racks, and a restart must not fire the whole set at once.
    property real lastHealth: 0
    property int lastRounds: 0
    property bool hadLock: false
    property bool hadThreat: false

    function update(dt: real) {
        if (root.ownship === null)
            return;

        const health = root.ownship.health;
        const rounds = root.roundsLeft();
        const holdsLock = root.holdsLock();
        const threatened = root.ownship.threatInbound !== null;

        if (health < root.lastHealth)
            Sfx.impact();
        if (rounds < root.lastRounds)
            Sfx.launch();
        if (holdsLock && !root.hadLock)
            Sfx.lock();
        if (threatened && !root.hadThreat)
            Sfx.threat();

        root.lastHealth = health;
        root.lastRounds = rounds;
        root.hadLock = holdsLock;
        root.hadThreat = threatened;
    }

    // Rounds left across the launch racks only. A flare pop spends a charge
    // too, and a decoy going over the side is not a launch — the pod has its
    // own sound to earn later, and it is not this one.
    function roundsLeft(): int {
        let total = 0;
        for (let i = 0; i < root.ownship.abilities.length; ++i) {
            const slot = root.ownship.abilities[i];
            if (slot.round !== null && slot.charges >= 0)
                total += slot.charges;
        }
        return total;
    }

    // Whether any guided rack is holding a return: the moment the shot the
    // pilot has been waiting on becomes available.
    function holdsLock(): bool {
        for (let i = 0; i < root.ownship.abilities.length; ++i) {
            const slot = root.ownship.abilities[i];
            if (slot.guided && slot.lock !== null)
                return true;
        }
        return false;
    }
}
