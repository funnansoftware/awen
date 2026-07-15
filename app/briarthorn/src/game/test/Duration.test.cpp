#include <chrono>

#include <gtest/gtest.h>

#include <game/Duration.hpp>

namespace
{
    using bt::game::Duration;

    TEST(DurationTest, ToSecondsConvertsFromAnyChronoDuration)
    {
        EXPECT_FLOAT_EQ(Duration{std::chrono::milliseconds{500}}.toSeconds().count(), 0.5F);
        EXPECT_FLOAT_EQ(Duration{std::chrono::seconds{2}}.toSeconds().count(), 2.0F);
        EXPECT_FLOAT_EQ(Duration{}.toSeconds().count(), 0.0F);
    }

    TEST(DurationTest, AddAndSubtractAccumulate)
    {
        auto total = Duration{};
        total += Duration{std::chrono::milliseconds{150}};
        total += Duration{std::chrono::milliseconds{150}};
        total -= Duration{std::chrono::milliseconds{100}};

        EXPECT_FLOAT_EQ(total.toSeconds().count(), 0.2F);
        EXPECT_TRUE(total >= Duration{std::chrono::milliseconds{100}});
        EXPECT_FALSE(total >= Duration{std::chrono::milliseconds{300}});
    }
}
