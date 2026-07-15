#include <chrono>

#include <gtest/gtest.h>

#include <game/Clock.hpp>
#include <game/Duration.hpp>

namespace
{
    using bt::game::Clock;
    using bt::game::Duration;
    using std::chrono::milliseconds;

    TEST(ClockTest, FixedSecondsReportsTheStep)
    {
        auto clock = Clock{};
        clock.setInterval(Duration{milliseconds{10}});

        EXPECT_NEAR(clock.getInterval().toSeconds().count(), 0.01F, 1e-6F);
    }

    TEST(ClockTest, AdvanceReleasesWholeSteps)
    {
        auto clock = Clock{};
        clock.setInterval(Duration{milliseconds{100}});

        EXPECT_EQ(clock.advance(Duration{milliseconds{250}}), 2); // -> two steps, 50 ms banked
        EXPECT_EQ(clock.advance(Duration{milliseconds{40}}), 0);  // 90 ms total, short of 100
        EXPECT_EQ(clock.advance(Duration{milliseconds{20}}), 1);  // 110 ms -> one step, 10 ms banked
    }

    TEST(ClockTest, AlphaExposesTheBankedRemainder)
    {
        auto clock = Clock{};
        clock.setInterval(Duration{milliseconds{100}});
        clock.advance(Duration{milliseconds{50}});

        EXPECT_NEAR(clock.alpha(), 0.5F, 1e-4F); // half a step sits in the accumulator
    }

    TEST(ClockTest, SetIntervalChangesTheRate)
    {
        auto clock = Clock{};
        clock.setInterval(Duration{milliseconds{100}});
        EXPECT_EQ(clock.advance(Duration{milliseconds{100}}), 1); // one 100 ms step

        clock.setInterval(Duration{milliseconds{50}});
        EXPECT_EQ(clock.advance(Duration{milliseconds{100}}), 2); // now two 50 ms steps
    }

    TEST(ClockTest, AdvanceCapsRunawayCatchUp)
    {
        auto clock = Clock{};
        clock.setInterval(Duration{milliseconds{100}});
        clock.setMaxSteps(3); // at most three steps per advance

        EXPECT_EQ(clock.advance(Duration{std::chrono::seconds{100}}), 3); // a huge stall is capped
        EXPECT_EQ(clock.advance(Duration{milliseconds{50}}), 0);          // backlog dropped, not chased
    }
}
