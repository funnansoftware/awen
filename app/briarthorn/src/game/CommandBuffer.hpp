#pragma once

#include <cstddef>
#include <vector>

#include <game/Command.hpp>

namespace bt::game
{
    class World;

    /// @brief The single, deferred seam for controller-driven state changes.
    ///
    /// Controllers — device input, AI drivers, UI — never write entity fields
    /// directly; they RECORD intent here, and the game loop drains the buffer with
    /// flush() at each fixed tick, before the systems run. That keeps every
    /// controller mutation ordered, deterministic and replay-friendly, and confines
    /// structural changes (despawns) to the tick boundary. Systems remain the
    /// authoritative tick-time mutators — they write fields directly in step();
    /// this governs the controller tier only. The C++ evolution of
    /// `lib/sim/systems/commands.dart` from immediate setters into a queue.
    class CommandBuffer
    {
    public:
        // Recording verbs — what a controller calls. Cheap: a push_back each.
        auto throttle(EntityId entity, float position) -> void;
        auto brake(EntityId entity, float position) -> void;
        auto steer(EntityId entity, float amount) -> void;
        auto boost(EntityId entity, float level) -> void;
        auto damage(EntityId entity, float amount) -> void;
        auto despawn(EntityId entity) -> void;

        /// @brief Record an already-built command (the generic escape hatch).
        /// @param command The already-built command to record.
        auto record(const Command& command) -> void;

        /// @brief Apply every recorded command to @p world, in record order, then clear.
        ///
        /// A command whose entity no longer exists is skipped.
        /// @param world The world to apply the recorded commands to.
        auto flush(World& world) -> void;

        [[nodiscard]] auto empty() const -> bool;
        [[nodiscard]] auto size() const -> std::size_t;
        auto clear() -> void;

    private:
        std::vector<Command> commands_;
    };
}
