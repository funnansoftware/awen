#include <game/Duration.hpp>

#include <chrono>
#include <compare>

using bt::game::Duration;

auto Duration::toSeconds() const -> Seconds
{
    return duration_;
}

auto Duration::operator+=(Duration other) noexcept -> Duration&
{
    duration_ += other.duration_;
    return *this;
}

auto Duration::operator-=(Duration other) noexcept -> Duration&
{
    duration_ -= other.duration_;
    return *this;
}

auto Duration::operator<=>(Duration other) const noexcept -> std::partial_ordering
{
    return duration_ <=> other.duration_;
}
