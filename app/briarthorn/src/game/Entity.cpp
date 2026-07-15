#include <game/Entity.hpp>

using bt::game::Entity;

auto Entity::topSpeed() const -> float
{
    return limits.topSpeed * speedBoost;
}
