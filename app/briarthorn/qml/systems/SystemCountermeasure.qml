import awen.entity
import "../database"
import "../model"

// Countermeasures, ported from briardart: consumes raised countermeasure
// intents into same-side decoy entities placed between the deployer and the
// round marked inbound on it — each one wearing the deployer's own signature,
// so a hostile seeker cannot pick between the two by loudness and re-homes on
// whichever is nearer, the decoy for exactly as long as the deployer keeps
// opening the range on it — and ages each decoy out again. Runs after
// SystemWeapon, so a popped flare is in play from the next tick.
System {
    id: root

    // The world decoys spawn into.
    required property World world

    // Live decoys, as {entity, life} entries.
    property var flares: []

    function update(dt: real) {
        root.deploy();
        root.age(dt);
    }

    function deploy() {
        const roster = root.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            const carrier = roster[i];
            for (let j = 0; j < carrier.abilities.length; ++j) {
                const slot = carrier.abilities[j];
                if (!(slot.def instanceof AbilityCountermeasure) || !slot.pending)
                    continue;
                slot.pending = false;
                if (!slot.ready)
                    continue;
                // A pop spends both, as a launch does; the flare pod happens to
                // cool in zero seconds, but the slot is what holds the rule.
                slot.charges = slot.charges > 0 ? slot.charges - 1 : slot.charges;
                slot.cooldownRemaining = slot.def.cooldown;
                // Thrown at the round it answers, so the decoy lands between
                // the two and is the nearer of the matching returns from the
                // moment it burns; where it goes from there is the deployer's
                // business. Popped at a clear sky it goes astern instead —
                // the doctrine when there is nothing to place it against.
                // Always the pod's full eject range, whatever the aspect, so
                // the deployer keeps its clearance from the warhead.
                const inbound = carrier.threatInbound;
                const bearing = inbound !== null ? Geo.bearing(carrier, inbound) : Geo.reciprocal(carrier.heading);
                const decoy = root.world.spawn("CM", slot.def.decoy, {
                    side: carrier.side,
                    owner: carrier,
                    posX: carrier.posX + Geo.offsetX(bearing, slot.def.ejectRange),
                    posY: carrier.posY + Geo.offsetY(bearing, slot.def.ejectRange),
                    heading: carrier.heading
                });
                // The whole trick, written after the spawn so it lands on top
                // of the kind's own rating instead of under it: the flare
                // returns exactly what the craft that popped it does, leaving
                // a seeker only range to tell the two apart. Copied at the
                // pop, not bound — what it imitates is the craft it left.
                decoy.stealth = carrier.stealth;
                root.flares.push({
                    entity: decoy,
                    life: slot.def.life
                });
            }
        }
    }

    // Burns each decoy down, despawning it at zero; entries whose decoy a
    // blast already removed just drop.
    function age(dt: real) {
        let changed = false;
        for (let i = 0; i < root.flares.length; ++i) {
            const entry = root.flares[i];
            entry.life -= dt;
            if (!root.world.entities.includes(entry.entity)) {
                changed = true;
                entry.life = 0;
            } else if (entry.life <= 0) {
                root.world.despawn(entry.entity);
                changed = true;
            }
        }
        if (changed)
            root.flares = root.flares.filter(entry => entry.life > 0);
    }
}
