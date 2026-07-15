#include <gtest/gtest.h>

#include <game/Heading.hpp>

namespace
{
    using bt::game::Heading;

    // Heading is a constexpr type: the wrap invariant holds in constant
    // expressions, pinned at compile time.
    static_assert(Heading{360.0F} == Heading{});
    static_assert(Heading{-90.0F}.degrees() == 270.0F);
    static_assert((Heading{350.0F} + 20.0F).degrees() == 10.0F);
    static_assert(Heading{}.turnTo(Heading{190.0F}) == -170.0F);

    TEST(HeadingTest, WrapsOntoCanonicalRange)
    {
        EXPECT_FLOAT_EQ(Heading{360.0F}.degrees(), 0.0F);
        EXPECT_FLOAT_EQ(Heading{-90.0F}.degrees(), 270.0F);
        EXPECT_FLOAT_EQ(Heading{725.0F}.degrees(), 5.0F);
        EXPECT_EQ(Heading{360.0F}, Heading{});
    }

    TEST(HeadingTest, TurnsWrapAcrossNorth)
    {
        auto heading = Heading{350.0F};
        heading += 20.0F;
        EXPECT_FLOAT_EQ(heading.degrees(), 10.0F);

        heading -= 20.0F;
        EXPECT_FLOAT_EQ(heading.degrees(), 350.0F);

        EXPECT_FLOAT_EQ((Heading{} - 1.0e-6F).degrees(), 0.0F); // ulp edge: never 360
    }

    TEST(HeadingTest, TurnToTakesTheShortestWay)
    {
        EXPECT_FLOAT_EQ(Heading{10.0F}.turnTo(Heading{350.0F}), -20.0F);
        EXPECT_FLOAT_EQ(Heading{350.0F}.turnTo(Heading{10.0F}), 20.0F);
        EXPECT_FLOAT_EQ(Heading{}.turnTo(Heading{180.0F}), -180.0F); // ties go left
    }
}
