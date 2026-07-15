#include <gtest/gtest.h>

#include <game/Entity.hpp>
#include <game/World.hpp>

namespace
{
    using bt::game::Entity;
    using bt::game::World;

    TEST(WorldTest, SpawnAssignsUniqueIdsAndFindsThem)
    {
        auto world = World{};
        const auto first = world.spawn(Entity{});
        const auto second = world.spawn(Entity{});

        EXPECT_NE(first, second);
        ASSERT_NE(world.find(first), nullptr);
        EXPECT_EQ(world.find(first)->id, first);
        EXPECT_EQ(world.entities().size(), 2U);
    }

    TEST(WorldTest, DespawnRemovesTheEntity)
    {
        auto world = World{};
        const auto id = world.spawn(Entity{});

        EXPECT_TRUE(world.despawn(id));
        EXPECT_EQ(world.find(id), nullptr);
        EXPECT_FALSE(world.despawn(id)); // already gone
    }
}
