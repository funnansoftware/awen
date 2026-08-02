import awen.entity
import "../database"
import "../model"

// Countermeasures, ported from briardart: consumes raised countermeasure
// intents into same-side decoy entities astern of the deployer — the decoy
// kind's own row makes it the loudest possible return, so a hostile seeker
// re-homes on it instead — and ages each decoy out again. Runs after
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
                // Thrown astern, so the decoy lands between the deployer and
                // the round chasing it and the range only opens from there.
                const rad = carrier.heading * Math.PI / 180;
                const decoy = root.world.spawn("CM", slot.def.decoy, {
                    side: carrier.side,
                    owner: carrier,
                    posX: carrier.posX - (Math.sin(rad) * slot.def.ejectRange),
                    posY: carrier.posY + (Math.cos(rad) * slot.def.ejectRange),
                    heading: carrier.heading
                });
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
