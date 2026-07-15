#include <game/CommandBuffer.hpp>

#include <algorithm>
#include <type_traits>
#include <variant>

#include <game/World.hpp>

using bt::game::Command;
using bt::game::CommandBuffer;
using bt::game::Damage;
using bt::game::Despawn;
using bt::game::Entity;
using bt::game::EntityId;
using bt::game::SetBoost;
using bt::game::SetBrake;
using bt::game::SetSteer;
using bt::game::SetThrottle;
using bt::game::World;

namespace
{
    [[nodiscard]] auto clamp01(float value) -> float
    {
        return std::clamp(value, 0.0F, 1.0F);
    }

    // One apply overload per settable command. The generic visitor below
    // resolves to the right one; Despawn is handled separately (it mutates the
    // world, not an entity), so it needs no overload here.
    auto apply(Entity& entity, const SetThrottle& command) -> void
    {
        entity.controls.throttle = clamp01(command.position);
    }

    auto apply(Entity& entity, const SetBrake& command) -> void
    {
        entity.controls.brake = clamp01(command.position);
    }

    auto apply(Entity& entity, const SetSteer& command) -> void
    {
        entity.controls.steer = std::clamp(command.amount, -1.0F, 1.0F);
    }

    auto apply(Entity& entity, const SetBoost& command) -> void
    {
        entity.controls.boost = clamp01(command.level);
    }

    auto apply(Entity& entity, const Damage& command) -> void
    {
        // Ignore non-positive damage (matching briardart's Commands.damage), so
        // a stray negative amount can never heal the entity.
        if (command.amount <= 0.0F)
        {
            return;
        }
        entity.health = std::max(0.0F, entity.health - command.amount);
    }
}

auto CommandBuffer::throttle(EntityId entity, float position) -> void
{
    commands_.emplace_back(SetThrottle{.entity = entity, .position = position});
}

auto CommandBuffer::brake(EntityId entity, float position) -> void
{
    commands_.emplace_back(SetBrake{.entity = entity, .position = position});
}

auto CommandBuffer::steer(EntityId entity, float amount) -> void
{
    commands_.emplace_back(SetSteer{.entity = entity, .amount = amount});
}

auto CommandBuffer::boost(EntityId entity, float level) -> void
{
    commands_.emplace_back(SetBoost{.entity = entity, .level = level});
}

auto CommandBuffer::damage(EntityId entity, float amount) -> void
{
    commands_.emplace_back(Damage{.entity = entity, .amount = amount});
}

auto CommandBuffer::despawn(EntityId entity) -> void
{
    commands_.emplace_back(Despawn{.entity = entity});
}

auto CommandBuffer::record(const Command& command) -> void
{
    commands_.push_back(command);
}

auto CommandBuffer::empty() const -> bool
{
    return commands_.empty();
}

auto CommandBuffer::size() const -> std::size_t
{
    return commands_.size();
}

auto CommandBuffer::clear() -> void
{
    commands_.clear();
}

auto CommandBuffer::flush(World& world) -> void
{
    for (const auto& command : commands_)
    {
        std::visit(
            [&world](const auto& payload) -> void
            {
                using T = std::decay_t<decltype(payload)>;
                if constexpr (std::is_same_v<T, Despawn>)
                {
                    world.despawn(payload.entity);
                }
                else
                {
                    auto* entity = world.find(payload.entity);
                    if (entity != nullptr)
                    {
                        apply(*entity, payload);
                    }
                }
            },
            command);
    }
    commands_.clear();
}
