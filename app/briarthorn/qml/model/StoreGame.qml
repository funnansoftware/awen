import awen.command
import "../commands"

// The game store: owns the player's craft and consumes every player intent
// on the bus. It outlives any scenario — levels swap, these handlers stay —
// and the declared handlers are its whole transition surface.
Store {
    id: store

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
