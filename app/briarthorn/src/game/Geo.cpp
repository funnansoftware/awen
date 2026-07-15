#include <game/Geo.hpp>

#include <cmath>
#include <numbers>

#include <game/Heading.hpp>

using bt::game::Geo;
using bt::game::Vec2;

namespace
{
    constexpr auto RadiansPerDegree = std::numbers::pi_v<float> / 180.0F;
}

auto Geo::offsetX(Heading heading, float distance) -> float
{
    return std::sin(heading.degrees() * RadiansPerDegree) * distance;
}

auto Geo::offsetY(Heading heading, float distance) -> float
{
    return -std::cos(heading.degrees() * RadiansPerDegree) * distance;
}

auto Geo::offset(Heading heading, float distance) -> Vec2
{
    return Vec2{.x = offsetX(heading, distance), .y = offsetY(heading, distance)};
}
