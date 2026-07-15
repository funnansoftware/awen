#pragma once

namespace bt::game
{
    class World;

    /// @brief The contract every simulation system satisfies: advance the world by
    /// one fixed step.
    ///
    /// The game loop calls step(world, dt) for each system in order, once per tick,
    /// after the command buffer has been flushed. Systems are the authoritative
    /// tick-time mutators — they write entity state directly. Ports
    /// `lib/sim/systems/system.dart` (step now takes the world explicitly rather
    /// than each system holding its own live entity list).
    class System
    {
    public:
        System() = default;
        virtual ~System() = default;
        System(const System&) = delete;
        auto operator=(const System&) -> System& = delete;
        System(System&&) noexcept = delete;
        auto operator=(System&&) noexcept -> System& = delete;

        virtual auto update(World& world, float dt) -> void = 0;
    };
}
