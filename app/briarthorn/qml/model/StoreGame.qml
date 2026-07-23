import awen.command
import "../commands"

// The game store: owns the player's craft and consumes every player intent
// on the bus. It outlives any scenario — levels swap, these handlers stay —
// and the declared handlers are its whole transition surface.
Store {
    id: store

    // Campaign meta-state the top bar reads: the shared credit purse. A
    // placeholder until an economy writes it; player-facing persistent state
    // belongs on the store, not on any one entity.
    property int credits: 1250

    // Ownship under player control.
    readonly property Entity ownship: Entity {
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Ownship
        radarFov: 60
        kinetic: 500
        maneuver: 12
        durable: 5
        compute: 6
        sensor: 60000
        stealth: 5
        // Condition: hull scaled from durability, fuel a full tank. Both start
        // topped off; SystemFuel draws the tank down as the player flies.
        maxHealth: durable * 20
        health: maxHealth
        maxFuel: 100
        fuel: maxFuel
    }

    CommandHandler {
        name: Verbs.steer
        onHandle: payload => store.ownship.commandedSteer = payload.value
    }

    CommandHandler {
        name: Verbs.throttle
        onHandle: payload => store.ownship.commandedThrottle = payload.value
    }
}
