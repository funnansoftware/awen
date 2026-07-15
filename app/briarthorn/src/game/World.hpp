#pragma once

#include <cstddef>
#include <vector>

#include <game/Entity.hpp>

namespace bt::game
{
    /// @brief The world's entity database and its one lifecycle owner.
    ///
    /// Every Entity that exists is created and destroyed here. Structural changes
    /// (spawn/despawn) go through the command buffer and land at tick boundaries,
    /// never mid-step, so a system can iterate entities() without the vector
    /// reallocating under it. A trimmed port of `lib/sim/model/world_model.dart`.
    class World
    {
    public:
        /// @brief Add @p entity to the world, assigning it a fresh id.
        /// @param entity The entity to add; its `id` field is overwritten.
        /// @return The fresh id assigned to the entity.
        auto spawn(Entity entity) -> EntityId;

        /// @brief Remove the entity with @p id, if present.
        /// @param id The id of the entity to remove.
        /// @return Whether an entity was removed.
        auto despawn(EntityId id) -> bool;

        /// @brief The live entity for @p id, or nullptr if none.
        ///
        /// Linear scan. The pointer is valid only until the next spawn/despawn — hold
        /// ids, not pointers.
        /// @param id The id to look up.
        /// @return A pointer to the live entity, or nullptr if none exists.
        [[nodiscard]] auto find(EntityId id) -> Entity*;
        [[nodiscard]] auto find(EntityId id) const -> const Entity*;

        /// @brief All entities, in spawn order — the list systems iterate each tick.
        /// @return The world's entity list.
        [[nodiscard]] auto entities() -> std::vector<Entity>&;
        [[nodiscard]] auto entities() const -> const std::vector<Entity>&;

        /// @brief The entity the world revolves around (ownship); NullEntity if none.
        /// @return The player entity's id, or NullEntity if none is set.
        [[nodiscard]] auto getPlayer() const -> EntityId;

        /// @brief Set the entity the world revolves around (ownship).
        /// @param id The id of the entity to treat as the player.
        auto setPlayer(EntityId id) -> void;

    private:
        std::vector<Entity> entities_;
        EntityId nextId_{1};
        EntityId player_{NullEntity};
    };
}
