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
    readonly property Entity ownship: Entity {
        classification: Classification.Kind.AircraftFighter
        side: Side.Kind.Ownship
        radarFov: 60
    }

    CommandHandler {
        name: Verbs.steer
        onHandle: payload => root.ownship.commandedSteer = payload.value
    }

    CommandHandler {
        name: Verbs.throttle
        onHandle: payload => root.ownship.commandedThrottle = payload.value
    }

    // Ability invocation routes to the named slot; activation is a no-op
    // while the slot is cooling or out of charges.
    CommandHandler {
        name: Verbs.ability
        onHandle: payload => {
            const slots = root.ownship.abilities;
            for (let i = 0; i < slots.length; ++i) {
                if (slots[i].def.name === payload.ability) {
                    slots[i].activate();
                    return;
                }
            }
        }
    }
}
