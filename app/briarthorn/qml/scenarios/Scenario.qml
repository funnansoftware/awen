import awen.entity
import "../model"

// Base type for a level: the entities and systems that live and die with
// it, packaged as one swappable slot in the game's run order. The player's
// craft and the command handlers stay outside, in the game store.
SystemGroup {
    // The level-owned entities; the player's craft is referenced, not owned.
    property list<Entity> entities
}
