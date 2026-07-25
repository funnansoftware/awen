import QtQml
import "../database"

// Ground-truth state for one object in the game world: identity, pose, control
// inputs and the six stats. Everything below defaults from the database row
// its classification names, so a spawn site names a kind and overrides only
// what makes this one different. Pure state — systems write it, the view reads
// it.
QtObject {
    id: entity

    // Identity. The definition row follows the classification, and is null for
    // a kind nothing can spawn.
    property string callsign: ""
    property int classification: Classification.Kind.Unknown
    property int side: Side.Kind.Unknown

    readonly property DataEntity def: Database.entityDataFor(entity.classification)

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
    property real radarFov: entity.def ? entity.def.radarFov : 360

    // Control inputs a pilot or behaviour system writes and SystemMovement
    // integrates: throttle 0..1, steer -1 (left) to 1 (right).
    property real commandedThrottle: 0
    property real commandedSteer: 0

    // The six stats, as the dimensionless 0..10 ratings GameRules prices (see
    // Stats). Never a game quantity — assigning one here re-derives every
    // capability below with it.
    property real kinetic: entity.def ? entity.def.stats.kinetic : 0
    property real maneuver: entity.def ? entity.def.stats.maneuver : 0
    property real durable: entity.def ? entity.def.stats.durable : 0
    property real compute: entity.def ? entity.def.stats.compute : 0
    property real sensor: entity.def ? entity.def.stats.sensor : 0
    property real stealth: entity.def ? entity.def.stats.stealth : 0

    // What those ratings afford, through the one rule table. Systems read
    // these rather than reaching for a stat and scaling it themselves.
    readonly property real topSpeed: GameRules.topSpeedFor(entity.kinetic) * entity.speedBoost
    readonly property real turnRate: GameRules.turnRateFor(entity.maneuver)
    readonly property real acceleration: GameRules.accelerationFor(entity.maneuver)
    readonly property real detectionRange: GameRules.detectionRangeFor(entity.sensor)
    readonly property real fuelBurn: GameRules.fuelBurnFor(entity.kinetic)

    // Condition: current and maximum hull integrity and fuel. Pure state —
    // SystemWeapon's blasts write health, SystemFuel writes fuel, the view
    // reads both. The maxima come from durability; both start full.
    property real maxHealth: GameRules.healthFor(entity.durable)
    property real health: entity.maxHealth
    property real maxFuel: GameRules.fuelCapacityFor(entity.durable)
    property real fuel: entity.maxFuel

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
    property list<AbilitySlot> abilities: entity.def ? entity.slotsFor(entity.def.abilities) : []

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
            slots.push(entity.slotFactory.createObject(entity, {
                def: def
            }));
        }
        return slots;
    }
}
