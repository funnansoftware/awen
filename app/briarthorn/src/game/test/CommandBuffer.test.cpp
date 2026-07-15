#include <gtest/gtest.h>

#include <game/CommandBuffer.hpp>
#include <game/Entity.hpp>
#include <game/World.hpp>

namespace
{
    using bt::game::CommandBuffer;
    using bt::game::Entity;
    using bt::game::World;

    TEST(CommandBufferTest, FlushAppliesClampedIntentThenClears)
    {
        auto world = World{};
        const auto id = world.spawn(Entity{});

        auto commands = CommandBuffer{};
        commands.throttle(id, 5.0F); // over-range -> clamps to 1
        commands.steer(id, -3.0F);   // under-range -> clamps to -1
        EXPECT_EQ(commands.size(), 2U);

        commands.flush(world);

        EXPECT_FLOAT_EQ(world.find(id)->controls.throttle, 1.0F);
        EXPECT_FLOAT_EQ(world.find(id)->controls.steer, -1.0F);
        EXPECT_TRUE(commands.empty()); // flush drains the buffer
    }

    TEST(CommandBufferTest, DamageIsAppliedAndFloorsAtZero)
    {
        auto world = World{};
        auto entity = Entity{};
        entity.health = 30.0F;
        const auto id = world.spawn(entity);

        auto commands = CommandBuffer{};
        commands.damage(id, 100.0F);
        commands.flush(world);

        EXPECT_FLOAT_EQ(world.find(id)->health, 0.0F);
    }

    TEST(CommandBufferTest, CommandsNamingADespawnedEntityAreSkipped)
    {
        auto world = World{};
        const auto id = world.spawn(Entity{});

        auto commands = CommandBuffer{};
        commands.despawn(id);
        commands.throttle(id, 1.0F); // applied after the despawn -> a safe no-op

        commands.flush(world);

        EXPECT_EQ(world.find(id), nullptr);
        EXPECT_EQ(world.entities().size(), 0U);
    }
}
