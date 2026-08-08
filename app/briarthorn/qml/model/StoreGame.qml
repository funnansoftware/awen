import QtQml
import awen.command
import "../commands"
import "../database"

// The game store: owns the player's craft and consumes every player intent
// on the bus. It outlives any scenario — levels swap, these handlers stay —
// and the declared handlers are its whole transition surface.
Store {
    id: root

    // Campaign meta-state the top bar reads: the shared credit purse. A
    // placeholder until an economy writes it; player-facing persistent state
    // belongs on the store, not on any one entity.
    property int credits: 1250

    // Ownship under player control: a stock fighter off the database — stats,
    // condition and the invocable loadout all come from that row — flown with
    // a narrower radar cone than the airframe's own, so the player has to
    // point at what they want to see.
    component PlayerCraft: Entity {
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Ownship
        radarFov: 60
        // Spawned already at cruise: the lever at rest commands idle, not a
        // stop, and the first post overwrites this binding.
        commandedThrottle: GameRules.throttleIdle
    }

    // The live craft. reset() owns the swap; everything else binds through
    // this property, so a fresh craft propagates everywhere on its own.
    property Entity ownship: PlayerCraft {}

    readonly property Component craftFactory: Component {
        PlayerCraft {}
    }

    CommandHandler {
        name: Verbs.steer
        onHandle: payload => root.ownship.commandedSteer = payload.value
    }

    CommandHandler {
        name: Verbs.throttle
        onHandle: payload => root.ownship.commandedThrottle = GameRules.throttleFor(payload.value)
    }

    // Ability invocation routes to the named slot as a press: it fires where
    // every check passes, holds the shot armed where one does not yet, stands
    // an already-armed slot back down, and refuses an empty rack outright.
    CommandHandler {
        name: Verbs.ability
        onHandle: payload => root.ownship.invoke(payload.ability)
    }

    // Replaces the player's craft with a factory-fresh one — QML's
    // constructor — so a game entered from the menu always starts clean and
    // no field-by-field restore drifts as Entity grows. The caller re-enrolls
    // the new craft; the world never holds the old one past its purge.
    function reset() {
        const spent = root.ownship;
        root.ownship = root.craftFactory.createObject(root) as Entity;
        spent.destroy();
    }
}
