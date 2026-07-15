#include <gtest/gtest.h>

#include <game/Entity.hpp>

namespace
{
    using bt::game::Entity;

    TEST(EntityTest, TopSpeedFoldsTheLiveBoostMultiplier)
    {
        auto entity = Entity{};
        entity.limits.topSpeed = 100.0F;
        entity.speedBoost = 1.5F;

        EXPECT_FLOAT_EQ(entity.topSpeed(), 150.0F);
    }
}
