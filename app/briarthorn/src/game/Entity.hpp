#pragma once

#include <cstdint>

#include <game/Controls.hpp>
#include <game/Heading.hpp>
#include <game/Limits.hpp>
#include <game/Vec2.hpp>

namespace bt::game
{
    /// @brief Stable handle to an entity.
    ///
    /// 0 is the null handle (no entity); the world hands out ids from 1 up, so a
    /// stale handle never silently aliases a live entity the way a reused vector
    /// index would.
    using EntityId = std::uint32_t;

    inline constexpr auto NullEntity = EntityId{0};

    /// @brief Ground-truth state for one moving object in the world: a position,
    /// a heading, the kinematic state, plus the latched Controls a controller
    /// sets (through the command buffer) and the Limits bounding what the
    /// airframe can do.
    ///
    /// Pure state, no behaviour — systems write these, the renderer reads them. A
    /// trimmed port of `lib/sim/model/entity.dart`: kinematics only for now, with
    /// stats, weapons and abilities still to come.
    struct Entity
    {
        EntityId id{NullEntity};

        // Kinematic state — the movement system writes these.
        Vec2 position{};
        Heading heading{};        ///< clockwise from north; wraps by construction
        float speed{0.0F};        ///< m/s
        float acceleration{0.0F}; ///< m/s^2 applied last tick (output only)
        float speedBoost{1.0F};   ///< live top-speed multiplier movement derives
                                  ///< from controls.boost (output only)

        Controls controls{}; ///< latched controller intent, applied on flush
        Limits limits{};     ///< capability ceilings; from stats/GameRules later

        float health{100.0F};

        /// @brief Top speed right now, with the afterburner multiplier folded in.
        /// @return limits.topSpeed scaled by the live speedBoost multiplier.
        [[nodiscard]] auto topSpeed() const -> float;
    };
}
