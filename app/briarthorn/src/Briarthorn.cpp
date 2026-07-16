#include <Briarthorn.hpp>

#include <memory>

#include <game/Duration.hpp>
#include <game/Entity.hpp>
#include <game/Vec2.hpp>
#include <game/systems/Movement.hpp>

using bt::Briarthorn;

namespace
{
    // Demo scaffolding: two static reference markers around the origin (metres).
    constexpr auto MarkerNorthX = 120.0F;
    constexpr auto MarkerNorthY = -80.0F;
    constexpr auto MarkerSouthX = -160.0F;
    constexpr auto MarkerSouthY = 120.0F;
}

Briarthorn::Briarthorn()
{
    clock_.setInterval(DefaultStepInterval); // seed the fixed step; setStepInterval() overrides it
    buildWorld();
    systems_.push_back(std::make_unique<game::Movement>());
}

auto Briarthorn::setStepInterval(game::Duration step) -> void
{
    clock_.setInterval(step);
}

auto Briarthorn::resetClock() -> void
{
    clock_.reset();
}

auto Briarthorn::buildWorld() -> void
{
    // Ownship at the origin, plus a couple of static markers so the
    // ownship-centred camera has fixed references to fly against.
    const auto ownship = game::Entity{};
    world_.setPlayer(world_.spawn(ownship));

    const auto north = game::Entity{.position = game::Vec2{.x = MarkerNorthX, .y = MarkerNorthY}};
    world_.spawn(north);

    const auto south = game::Entity{.position = game::Vec2{.x = MarkerSouthX, .y = MarkerSouthY}};
    world_.spawn(south);
}

auto Briarthorn::update() -> void
{
    // Fold the real time elapsed since the last call into the chrono clock; it
    // returns how many fixed steps are now due (0..maxSteps).
    const auto steps = clock_.tick();
    const auto dt = clock_.getInterval().toSeconds();

    for (auto i = 0; i < steps; ++i)
    {
        // Controller tier first (apply this tick's recorded intent), then the
        // authoritative systems integrate it.
        commands_.flush(world_);

        for (const auto& system : systems_)
        {
            system->update(world_, dt.count());
        }
    }
}

auto Briarthorn::world() -> game::World&
{
    return world_;
}

auto Briarthorn::world() const -> const game::World&
{
    return world_;
}

auto Briarthorn::commands() -> game::CommandBuffer&
{
    return commands_;
}
