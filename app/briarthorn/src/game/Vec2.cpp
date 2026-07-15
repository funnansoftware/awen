#include <game/Vec2.hpp>

#include <cmath>

using bt::game::Vec2;

auto Vec2::lengthSquared() const -> float
{
    return (x * x) + (y * y);
}

auto Vec2::length() const -> float
{
    return std::sqrt(lengthSquared());
}

auto bt::game::operator+(Vec2 a, Vec2 b) -> Vec2
{
    return Vec2{.x = a.x + b.x, .y = a.y + b.y};
}

auto bt::game::operator-(Vec2 a, Vec2 b) -> Vec2
{
    return Vec2{.x = a.x - b.x, .y = a.y - b.y};
}

auto bt::game::operator*(Vec2 v, float scale) -> Vec2
{
    return Vec2{.x = v.x * scale, .y = v.y * scale};
}
