#include <bit>
#include <cmath>
#include <cstdint>
#include <limits>

#include <gtest/gtest.h>

#include <game/Geo.hpp>

namespace
{
    using bt::game::Geo;

    // The wrap is constexpr: the ulp edge holds in constant expressions too.
    static_assert(Geo::wrap360(-1.0e-6F) == 0.0F);

    TEST(GeoTest, WrapsAnglesOntoTheirCanonicalRange)
    {
        EXPECT_FLOAT_EQ(Geo::wrap360(370.0F), 10.0F);
        EXPECT_FLOAT_EQ(Geo::wrap360(-10.0F), 350.0F);
        EXPECT_FLOAT_EQ(Geo::wrap180(190.0F), -170.0F);
    }

    TEST(GeoTest, WrapNeverReturnsTheOpenBound)
    {
        EXPECT_FLOAT_EQ(Geo::wrap360(360.0F), 0.0F);
        // A tiny negative remainder rounds up to exactly 360 when 360 is added
        // (the float ulp there is ~3e-5); the wrap must fold that onto 0.
        EXPECT_FLOAT_EQ(Geo::wrap360(-1.0e-6F), 0.0F);
        EXPECT_FLOAT_EQ(Geo::wrap180(180.0F), -180.0F); // +180 folds to -180
    }

    TEST(GeoTest, WrapMatchesFmodAcrossTheFloatRange)
    {
        // wrap360 computes its remainder by constexpr shift-subtract and claims
        // results bit-identical to std::fmod; sweep both signs of the float
        // range (a prime stride touches every exponent) to hold it to that.
        const auto reference = [](float deg)
        {
            const auto wrapped = std::fmod(deg, 360.0F);
            const auto canonical = wrapped < 0.0F ? wrapped + 360.0F : wrapped;
            return canonical >= 360.0F ? 0.0F : canonical;
        };

        constexpr auto MaxBits = std::bit_cast<std::uint32_t>(std::numeric_limits<float>::max());
        for (auto bits = std::uint32_t{0}; bits < MaxBits; bits += 65521)
        {
            const auto value = std::bit_cast<float>(bits);
            ASSERT_EQ(Geo::wrap360(value), reference(value)) << "deg=" << value;
            ASSERT_EQ(Geo::wrap360(-value), reference(-value)) << "deg=" << -value;
        }
    }
}
