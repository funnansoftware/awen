import awen.entity
import "../model"

// Base type for a level: the initial conditions and the entities that exist
// in it, packaged as one swappable slot in the game's run order. Behaviour
// belongs on the entities as aspect fields the shared systems process — a
// scenario never loads systems of its own; the group base is only for a
// scenario that must direct events as they unfold (the launch screen's wave
// director). The player's craft and the command handlers stay outside, in
// the game store.
SystemGroup {
    id: root

    // The level-owned entities; the player's craft is referenced, not owned.
    property list<Entity> entities
}
