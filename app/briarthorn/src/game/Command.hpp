#pragma once

#include <variant>

#include <game/Entity.hpp>

namespace bt::game
{
    /// @brief The vocabulary a controller uses to ask for a change.
    ///
    /// Each command names its target entity by id (not pointer), so it survives a
    /// vector realloc and refers to nothing once its entity despawns. Values are
    /// stored raw and clamped when applied. CommandBuffer::flush() applies them at
    /// the tick edge.
    struct SetThrottle
    {
        EntityId entity{NullEntity};
        float position{0.0F}; ///< 0..1
    };

    struct SetBrake
    {
        EntityId entity{NullEntity};
        float position{0.0F}; ///< 0..1
    };

    struct SetSteer
    {
        EntityId entity{NullEntity};
        float amount{0.0F}; ///< -1..1
    };

    struct SetBoost
    {
        EntityId entity{NullEntity};
        float level{0.0F}; ///< 0..1
    };

    struct Damage
    {
        EntityId entity{NullEntity};
        float amount{0.0F};
    };

    struct Despawn
    {
        EntityId entity{NullEntity};
    };

    /// @brief One recorded intent.
    ///
    /// A closed variant rather than a virtual command hierarchy: the set is small
    /// and known, each payload is trivially copyable, and flush() dispatches the
    /// lot with a single std::visit.
    using Command = std::variant<SetThrottle, SetBrake, SetSteer, SetBoost, Damage, Despawn>;
}
