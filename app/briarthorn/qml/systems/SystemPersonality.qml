import QtQml
import awen.entity
import "../database"
import "../model"

// How a personality-carrying entity fights the target its scenario points:
// each tick it prices one situation, advances the stance machine with dt and
// arms the maneuver and trigger machinery the stance chose — it never steers
// or shoots itself, and a frozen sim freezes every mind mid-dwell.
System {
    id: root

    // The world's roster; entities without a personality are passed over.
    property list<Entity> entities

    readonly property Component mindFactory: Component {
        PersonalityState {}
    }

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity.personality === "")
                continue;
            if (entity.mind === null)
                root.attach(entity);
            if (entity.mind.def === null)
                continue;
            const s = root.situationOf(entity);
            root.advance(entity, s, dt);
            root.arm(entity, s);
        }
    }

    // Builds the mind on the entity's first tick — construction inside sim
    // time, so a factory-reset craft gets a factory-fresh mind. An
    // unregistered name warns once and leaves a def-less mind behind.
    function attach(entity: Entity) {
        const def = Personalities.defFor(entity.personality);
        entity.mind = root.mindFactory.createObject(entity, {
            def: def,
            baseHoldoff: entity.engageHoldoff,
            baseAbility: entity.engageAbility
        }) as PersonalityState;
        if (def === null) {
            console.warn("SystemPersonality: no registered personality named \"" + entity.personality + "\"");
            return;
        }
        const flown = [];
        const owned = [];
        for (let i = 0; i < def.stances.length; ++i) {
            const m = def.stances[i].maneuver !== "" ? Maneuvers.make(def.stances[i].maneuver, entity.mind) : null;
            flown.push(m);
            if (m !== null)
                owned.push(m);
        }
        entity.mind.maneuvers = flown;
        entity.maneuvers = owned;
        entity.mind.stance = def.stances[0];
        root.vet(def);
    }

    // Warns about any switch destination the definition lacks and any stance
    // firing an unregistered launch, so a typo'd name surfaces at spawn
    // instead of as a silent hold mid-fight.
    function vet(def: Personality) {
        for (let i = 0; i < def.switches.length; ++i)
            root.vetSwitch(def, def.switches[i]);
        for (let i = 0; i < def.stances.length; ++i) {
            const stance = def.stances[i];
            if (stance.ability !== "" && !(Abilities.defFor(stance.ability) instanceof AbilityLaunch))
                console.warn("SystemPersonality: personality \"" + def.name + "\" stance \"" + stance.name + "\" fires \"" + stance.ability + "\", which names no registered launch ability");
            for (let j = 0; j < stance.switches.length; ++j)
                root.vetSwitch(def, stance.switches[j]);
        }
    }

    function vetSwitch(def: Personality, sw: Switch) {
        if (def.stanceFor(sw.to) === null)
            console.warn("SystemPersonality: personality \"" + def.name + "\" switches to an unknown stance \"" + sw.to + "\"");
    }

    // One priced fact sheet per entity per tick: every span an envelope,
    // never a raw metre. threat reads the mark SystemThreat pinned, decoy
    // the flare of the entity's own that a round is riding.
    function situationOf(entity: Entity): var {
        const target = entity.engageTarget;
        return {
            entity: entity,
            target: target,
            range: target !== null ? Geo.distance(entity, target) : Infinity,
            reach: entity.weaponReach,
            targetReach: target !== null ? target.weaponReach : 0,
            threat: entity.threatInbound,
            threatRange: entity.threatInbound !== null ? Geo.distance(entity, entity.threatInbound) : Infinity,
            decoy: root.seducedOf(entity),
            // A hull never given health is unkillable, so it is never hurt.
            healthFrac: entity.maxHealth > 0 ? entity.health / entity.maxHealth : 1,
            rounds: root.roundsOf(entity),
            outbound: root.outboundOf(entity)
        };
    }

    // Whether a round of the entity's own is still in flight — what a
    // shoot-look-shoot stance cranks behind.
    function outboundOf(entity: Entity): bool {
        for (let i = 0; i < root.entities.length; ++i) {
            const e = root.entities[i];
            if (e.weapon !== null && e.owner === entity)
                return true;
        }
        return false;
    }

    // The decoy of the entity's own that a round is currently locked on —
    // the pop that took. A seduced flare wears the same signature as the
    // craft that popped it, so the seeker holds whichever of the two it is
    // nearer: the flare keeps the round only while its deployer flies away
    // from it, and that is the one fact a defeating stance needs. Null once
    // the round is off it, burnt out, killed or gone.
    function seducedOf(entity: Entity): Entity {
        for (let i = 0; i < root.entities.length; ++i) {
            const round = root.entities[i];
            if (round.weapon === null || round.weapon.target === null)
                continue;
            const lock = round.weapon.target;
            if (lock.decoy && lock.owner === entity)
                return lock;
        }
        return null;
    }

    // Rounds left across the launch rack; any unlimited slot reads Infinity.
    function roundsOf(entity: Entity): real {
        let rounds = 0;
        for (let i = 0; i < entity.abilities.length; ++i) {
            const slot = entity.abilities[i];
            if (!(slot.def instanceof AbilityLaunch))
                continue;
            if (slot.charges === -1)
                return Infinity;
            rounds += slot.charges;
        }
        return rounds;
    }

    // First-hold-wins over the personality's switches then the stance's,
    // skipping any that name the stance already held — satisfied, never
    // blocking — so a survival switch further down still fires out of a
    // pinned stance. Dwell accumulates only while the same switch stays
    // first.
    function advance(entity: Entity, s: var, dt: real) {
        const mind = entity.mind;
        const first = root.firstSwitch(mind, s);
        if (first === null) {
            mind.pending = null;
            mind.dwell = 0;
            return;
        }
        if (mind.pending !== first) {
            mind.pending = first;
            mind.dwell = 0;
        }
        mind.dwell += dt;
        if (mind.dwell >= first.dwell) {
            // A destination the definition lacks was warned at attach; the
            // stance holds rather than poisoning the tick with a null.
            const next = mind.def.stanceFor(first.to);
            if (next !== null)
                mind.stance = next;
            mind.pending = null;
            mind.dwell = 0;
        }
    }

    // The highest-priority holding switch that would actually move the
    // stance, or null when none would.
    function firstSwitch(mind: PersonalityState, s: var): Switch {
        for (let i = 0; i < mind.def.switches.length; ++i) {
            const sw = mind.def.switches[i];
            if (sw.to !== mind.stance.name && sw.holds(s))
                return sw;
        }
        for (let i = 0; i < mind.stance.switches.length; ++i) {
            const sw = mind.stance.switches[i];
            if (sw.to !== mind.stance.name && sw.holds(s))
                return sw;
        }
        return null;
    }

    // Points exactly the current stance's maneuver — the targets drive the
    // maneuvers' own engaged bindings — prices its standoff, and sets the
    // trigger posture SystemEngage obeys.
    function arm(entity: Entity, s: var) {
        const mind = entity.mind;
        const stance = mind.stance;
        const current = mind.maneuverFor(stance);
        const reference = root.referenceOf(stance, s);
        for (let i = 0; i < mind.maneuvers.length; ++i) {
            const m = mind.maneuvers[i];
            if (m !== null)
                m.target = m === current ? reference : null;
        }
        if (current !== null && stance.standoff > 0 && "standoff" in current) {
            let span = stance.standoffOf === Envelope.Kind.OwnWeapon ? s.reach : stance.standoffOf === Envelope.Kind.TargetWeapon ? s.targetReach : entity.detectionRange;
            // An unarmed target still needs a ring to ride.
            if (span <= 0)
                span = s.reach;
            if (span > 0)
                current.standoff = stance.standoff * span;
        }
        entity.engageHold = stance.holdFire;
        entity.engageHoldoff = stance.holdoff >= 0 ? stance.holdoff : mind.baseHoldoff;
        entity.engageAbility = stance.ability !== "" ? stance.ability : mind.baseAbility;
    }

    // What the stance's maneuver flies against: the inbound round or the
    // seduced decoy where the stance names one, the engage target both as
    // the default and as the fallback while there is neither.
    function referenceOf(stance: Stance, s: var): Entity {
        if (stance.reference === Stance.Reference.Threat && s.threat !== null)
            return s.threat;
        if (stance.reference === Stance.Reference.Decoy && s.decoy !== null)
            return s.decoy;
        return s.target;
    }
}
