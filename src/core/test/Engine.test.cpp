#include <awen/test/Test.hpp>

import awen.core.engine;

TEST(Engine, Constructor)
{
    const awen::core::Engine engine;
    EXPECT_TRUE(true);
}

TEST(Engine, Run)
{
    awen::core::Engine engine;
    EXPECT_EQ(engine.run(), EXIT_SUCCESS);
}

UNIT_TEST(Engine, Update)
{
    awen::core::Engine engine;

    auto connection = engine.onUpdate([](std::chrono::duration<float> x) { EXPECT_TRUE(x.count() >= 0); });

    EXPECT_EQ(engine.run(), EXIT_SUCCESS);
}

UNIT_TEST(Engine, UpdateFixed)
{
    awen::core::Engine engine;

    auto connection = engine.onUpdateFixed([](std::chrono::duration<float> x) { EXPECT_TRUE(x.count() >= 0); });

    EXPECT_EQ(engine.run(), EXIT_SUCCESS);
}

UNIT_TEST(Engine, UpdateFixedLimit)
{
    awen::core::Engine engine;

    constexpr auto expectedLimit = 5;
    engine.setUpdateFixedLimit(expectedLimit);
    EXPECT_EQ(engine.getUpdateFixedLimit(), expectedLimit);
}

UNIT_TEST(Engine, UpdateFixedInterval)
{
    awen::core::Engine engine;

    constexpr auto interval = std::chrono::milliseconds(16);
    engine.setUpdateFixedInterval(interval);
    EXPECT_EQ(engine.getUpdateFixedInterval(), interval);
}