import QtQml
import "../database"

// Ground-truth state for one object in the game world: identity, pose, control
// inputs and the six stats. Everything below defaults from the database row
// its classification names, so a spawn site names a kind and overrides only
// what makes this one different. Pure state — systems write it, the view reads
// it.
QtObject {
    id: root

    // Identity. The definition row follows the classification, and is null for
    // a kind nothing can spawn.
    property string callsign: ""
    property int classification: Classification.Kind.Unknown
    property int side: Side.Kind.Unknown

    readonly property DataEntity def: Database.entityDataFor(root.classification)

    // World position in metres (1 px = 1 m, +x east, +y south) and facing in
    // degrees clockwise from north, kept in [0, 360).
    property real posX: 0
    property real posY: 0
    property real heading: 0

    // Ground speed in m/s: SystemMovement eases it toward what the throttle
    // commands and integrates the pose from it.
    property real speed: 0

    // Multiplier on the top-speed ceiling the kinetic rating sets, so a
    // munition's motor can carry it past what any airframe can do. 1 at rest.
    property real speedBoost: 1

    // The radar's total field-of-view cone in degrees, centred on heading;
    // 360 is an all-round sensor.
    property real radarFov: root.def ? root.def.radarFov : 360

    // Control inputs a pilot or behaviour system writes and SystemMovement
    // integrates: throttle 0..1, steer -1 (left) to 1 (right).
    property real commandedThrottle: 0
    property real commandedSteer: 0

    // Behaviour aspects: every system runs against the whole world and
    // processes the entities carrying its aspect, so a scenario arms
    // behaviour by setting fields at spawn — never by loading systems of its
    // own. A null target or a cleared flag simply opts the entity out.

    // The movement behaviours this entity flies, in priority order:
    // SystemManeuver hands the stick to the first engaged one each tick, and
    // an empty (or fully stood-down) list leaves the commands to the pilot.
    property list<Maneuver> maneuvers

    // The temperament SystemPersonality flies this entity with, defaulting
    // from its kind; empty opts out. A personality owns maneuvers,
    // engageHold and engageHoldoff — a director must not share an entity
    // with one.
    property string personality: root.def ? root.def.personality : ""

    // The live stance machine, built by SystemPersonality on the first
    // tick; reassigning personality mid-life is not supported.
    property PersonalityState mind: null

    // SystemEngage shoots at this inside the envelope. holdoff (s) paces the
    // launches; the timer is its run-down state, seedable to stagger a
    // wave's opening shots; engageHold stands the shooter down while true —
    // a director's salvo cap.
    property Entity engageTarget: null
    property real engageHoldoff: 6
    property real engageTimer: 0
    property bool engageHold: false

    // SystemThreat pops this entity's flares at inbound guided rounds; the
    // timer spaces the pops so each decoy gets its chance to seduce.
    property bool threatReflex: false
    property real threatTimer: 0

    // The nearest round SystemThreat marked inbound this tick — guided or
    // not; both the flare reflex and SystemPersonality read this one fact.
    property Entity threatInbound: null

    // SystemFuel drains the tank; the launch screen's demo craft clears this
    // so an endless showing never runs dry.
    property bool burnsFuel: true

    // The six stats, as the dimensionless 0..10 ratings GameRules prices (see
    // Stats). Never a game quantity — assigning one here re-derives every
    // capability below with it.
    property real kinetic: root.def ? root.def.stats.kinetic : 0
    property real maneuver: root.def ? root.def.stats.maneuver : 0
    property real durable: root.def ? root.def.stats.durable : 0
    property real compute: root.def ? root.def.stats.compute : 0
    property real sensor: root.def ? root.def.stats.sensor : 0
    property real stealth: root.def ? root.def.stats.stealth : 0

    // What those ratings afford, through the one rule table. Systems read
    // these rather than reaching for a stat and scaling it themselves.
    readonly property real topSpeed: GameRules.topSpeedFor(root.kinetic) * root.speedBoost
    readonly property real turnRate: GameRules.turnRateFor(root.maneuver)
    readonly property real acceleration: GameRules.accelerationFor(root.maneuver)
    readonly property real detectionRange: GameRules.detectionRangeFor(root.sensor)
    readonly property real fuelBurn: GameRules.fuelBurnFor(root.kinetic)

    // The longest reach across the rack's launch slots — capability, not
    // stock, so the envelope survives an empty magazine.
    readonly property real weaponReach: root.reachFrom(root.abilities)

    function reachFrom(slots: list<AbilitySlot>): real {
        let reach = 0;
        for (let i = 0; i < slots.length; ++i) {
            const launch = slots[i].def as AbilityLaunch;
            if (launch === null)
                continue;
            const round = Database.weaponDataFor(launch.weapon);
            if (round !== null)
                reach = Math.max(reach, round.reach);
        }
        return reach;
    }

    // Condition: current and maximum hull integrity and fuel. Pure state —
    // SystemWeapon's blasts write health, SystemFuel writes fuel, the view
    // reads both. The maxima come from durability; both start full.
    property real maxHealth: GameRules.healthFor(root.durable)
    property real health: root.maxHealth
    property real maxFuel: GameRules.fuelCapacityFor(root.durable)
    property real fuel: root.maxFuel

    // Condition as fractions of full, 0..1, and zero where there is nothing to
    // fill — every gauge and readout reads these rather than dividing for
    // itself and clamping again.
    readonly property real healthFrac: root.maxHealth > 0 ? Math.max(0, Math.min(1, root.health / root.maxHealth)) : 0
    readonly property real fuelFrac: root.maxFuel > 0 ? Math.max(0, Math.min(1, root.fuel / root.maxFuel)) : 0

    // Whether this entity is an expendable decoy rather than a craft or a
    // round: true of a popped flare, which wears its deployer's signature
    // and so holds a seeker only while the deployer opens the range on it.
    readonly property bool decoy: root.def ? root.def.decoy : false

    // The entity that launched or deployed this one; null for craft. Fuzes
    // ignore anything the owner also owns, the blast spares the owner and a
    // guided seeker sees only what the owner's radar illuminates.
    property Entity owner: null

    // The munition role state; non-null only when this entity is a missile.
    property Weapon weapon: null

    readonly property Component slotFactory: Component {
        AbilitySlot {}
    }

    // The abilities this entity can invoke, as live slots. Left alone it
    // carries the loadout its kind does, so arming an airframe is a database
    // edit and nothing else; a spawn site that assigns its own list overrides
    // the whole rack.
    property list<AbilitySlot> abilities: root.def ? root.slotsFor(root.def.abilities) : []

    // The slot holding a shot armed, or null. invoke() keeps it to one, so
    // every arming cue — the rack's button, the scope's envelope, the lock
    // bracket and the arming readout — always speaks for the same weapon.
    readonly property AbilitySlot armedAbility: {
        for (let i = 0; i < root.abilities.length; ++i) {
            if (root.abilities[i].armed)
                return root.abilities[i];
        }
        return null;
    }

    // A pilot's press on one ability: the second press on an armed slot stands
    // it down, and arming a slot stands every other one down first. The bare
    // slot's activate() is the raised-intent primitive behaviour systems use;
    // this is the only caller that means "again".
    function invoke(name: string) {
        let picked = null;
        for (let i = 0; i < root.abilities.length; ++i) {
            const slot = root.abilities[i];
            if (slot.def !== null && slot.def.name === name) {
                picked = slot;
                break;
            }
        }
        if (picked === null)
            return;
        if (picked.armed) {
            picked.armed = false;
            return;
        }
        picked.activate();
        // Only one weapon is ever held armed, so the cues always speak for the
        // same one. A press that fired outright armed nothing and stands
        // nothing down — popping a flare must not drop a held missile shot.
        if (!picked.armed)
            return;
        for (let i = 0; i < root.abilities.length; ++i) {
            if (root.abilities[i] !== picked)
                root.abilities[i].armed = false;
        }
    }

    // One live slot per named ability. An unregistered name is dropped with a
    // warning: silently it costs a missing ability, a missing binding and a
    // missing settings row, with nothing anywhere to notice it by.
    function slotsFor(names: list<string>): list<AbilitySlot> {
        const slots = [];
        for (let i = 0; i < names.length; ++i) {
            const def = Abilities.defFor(names[i]);
            if (def === null) {
                console.warn("Entity: no registered ability named \"" + names[i] + "\", dropping it from the loadout");
                continue;
            }
            slots.push(root.slotFactory.createObject(root, {
                def: def
            }));
        }
        return slots;
    }
}
