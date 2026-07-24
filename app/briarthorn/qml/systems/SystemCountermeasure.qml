import awen.entity
import "../model"

// Countermeasures, ported from briardart: consumes raised flare intents
// into same-side decoy entities at the deployer — stealth 0, the loudest
// possible return, so a hostile seeker re-homes on the decoy instead — and
// ages each decoy out again. Runs after SystemWeapon, so a popped flare is
// in play from the next tick.
System {
    id: countermeasure

    // The world decoys spawn into.
    required property World world

    // Seconds a decoy burns before it despawns.
    property real flareLife: 10

    // Live decoys, as {entity, life} entries.
    property var flares: []

    function update(dt: real) {
        countermeasure.deploy();
        countermeasure.age(dt);
    }

    function deploy() {
        const roster = countermeasure.world.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            const carrier = roster[i];
            for (let j = 0; j < carrier.abilities.length; ++j) {
                const slot = carrier.abilities[j];
                if (!(slot.def instanceof AbilityFlare) || !slot.pending)
                    continue;
                slot.pending = false;
                if (!slot.ready)
                    continue;
                slot.charges = slot.charges > 0 ? slot.charges - 1 : slot.charges;
                const decoy = countermeasure.world.spawn("CM", {
                    classification: Classification.Kind.Decoy,
                    side: carrier.side,
                    owner: carrier,
                    posX: carrier.posX,
                    posY: carrier.posY,
                    heading: carrier.heading,
                    stealth: 0,
                    maxHealth: 1,
                    health: 1
                });
                countermeasure.flares.push({
                    entity: decoy,
                    life: countermeasure.flareLife
                });
            }
        }
    }

    // Burns each decoy down, despawning it at zero; entries whose decoy a
    // blast already removed just drop.
    function age(dt: real) {
        let changed = false;
        for (let i = 0; i < countermeasure.flares.length; ++i) {
            const entry = countermeasure.flares[i];
            entry.life -= dt;
            if (!countermeasure.world.entities.includes(entry.entity)) {
                changed = true;
                entry.life = 0;
            } else if (entry.life <= 0) {
                countermeasure.world.despawn(entry.entity);
                changed = true;
            }
        }
        if (changed)
            countermeasure.flares = countermeasure.flares.filter(entry => entry.life > 0);
    }
}
