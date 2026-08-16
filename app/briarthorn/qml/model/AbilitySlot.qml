import QtQml
import "../database"

// One ability as carried by an entity: the definition row plus the live
// cooldown, charge, lock and intent state. activate() is the single entry
// point player input and AI share — it fires the slot when every check the
// rack is showing passes, holds the shot armed when one of them does not yet,
// and refuses outright when none of them ever will.
QtObject {
    id: root

    // Why a press would not put anything in the air right now, or None where
    // it would. The clock and the magazine the slot rates itself; the lock
    // states come off what SystemWeapon surveys, which is the only thing that
    // knows what a seeker can actually take.
    enum Impediment {
        None,
        Cooling,
        Empty,
        NoLock,
        Distant,
        NoTarget
    }

    // The ability definition this slot instantiates.
    property Ability def: null

    // Seconds until ready again and rounds left (-1 is unlimited); the
    // consuming system spends both.
    property real cooldownRemaining: 0
    property int charges: def ? def.charges : -1

    // The raised intent, cleared by the consuming system.
    property bool pending: false

    // A shot held against a check that has not passed yet: the consuming
    // system launches it the tick the check does pass, and clears this with
    // it, so one arming is one round. Standing it down again is the caller's
    // (a second press through Entity.invoke).
    property bool armed: false

    // The trigger position of an automatic slot: while down, the consuming
    // system fires a round every time the cooldown allows, and letting go is
    // the only way to stop. The pilot writes it through Entity.invoke and
    // Entity.release; SystemEngage grips and releases it for AI shooters.
    // Meaningless on a slot whose definition is not automatic.
    property bool held: false

    readonly property bool ready: cooldownRemaining <= 0 && charges !== 0

    // The munition this slot launches, and whether that round needs a lock
    // before it will leave the rail; null and false for an ability that
    // launches nothing.
    readonly property DataWeapon round: {
        const launch = root.def as AbilityLaunch;
        return launch !== null ? Database.weaponDataFor(launch.weapon) : null;
    }
    readonly property bool guided: root.round !== null && root.round.guided

    // How far a shot from this slot can take a target: the shorter of what the
    // seeker acquires inside and what the round can physically fly, so an
    // offered shot is one that can actually arrive. This is the envelope the
    // scope paints while the slot is armed.
    readonly property real reach: {
        if (root.round === null)
            return 0;
        return root.guided ? Math.min(root.round.seekerRange, root.round.reach) : root.round.reach;
    }

    // The return a launch would take right now, and — where it has none —
    // whether the radar is holding one anyway, too far out for the round.
    // SystemWeapon writes both every tick.
    property Entity lock: null
    property bool distant: false

    // Whether the launcher designates its targets and has designated nothing:
    // the impediment a press meets before any radar question is asked.
    // SystemWeapon writes it with the lock.
    property bool undesignated: false

    // Rounds from this slot currently in the air. SystemWeapon recomputes it
    // from the roster every tick rather than counting launches, so every
    // despawn path — detonation, a world sweep — self-heals to the truth.
    property int away: 0

    // Whether a launch would happen this instant: everything the consuming
    // system checks, in the one place the rack, the scope and the trigger all
    // read it from.
    readonly property bool valid: root.ready && (!root.guided || root.lock !== null)

    // What the controls colour themselves by: valid this instant, or an
    // automatic slot with rounds left — its hold always streams, and a ready
    // light strobing at the rate of fire would say nothing.
    readonly property bool willing: root.valid || (root.def !== null && root.def.automatic && root.charges !== 0)

    readonly property int impediment: {
        if (root.charges === 0)
            return AbilitySlot.Impediment.Empty;
        if (root.cooldownRemaining > 0)
            return AbilitySlot.Impediment.Cooling;
        if (root.guided && root.lock === null) {
            if (root.undesignated)
                return AbilitySlot.Impediment.NoTarget;
            return root.distant ? AbilitySlot.Impediment.Distant : AbilitySlot.Impediment.NoLock;
        }
        return AbilitySlot.Impediment.None;
    }

    // The cooldown still to run as a fraction of this ability's own — 1 the
    // moment it pops, 0 once ready — so a long reload and a short one both
    // wind a readiness dial over its full sweep.
    readonly property real cooling: def && def.cooldown > 0 ? cooldownRemaining / def.cooldown : 0

    // Raised when an invocation could never have fired — an empty rack. The
    // control flashes on it, so a dead press answers rather than vanishing.
    signal refused

    // Idempotent by design: a behaviour system asking twice arms once and
    // never stands its own shot down. The press's toggle lives on
    // Entity.invoke, which is the only caller that means "again".
    function activate() {
        if (root.def === null)
            return;
        if (root.charges === 0) {
            root.refused();
            return;
        }
        if (root.valid) {
            root.pending = true;
            return;
        }
        root.armed = true;
    }
}
