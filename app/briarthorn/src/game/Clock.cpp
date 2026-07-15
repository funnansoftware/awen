#include <game/Clock.hpp>

using bt::game::Clock;
using bt::game::Duration;

auto Clock::setInterval(Duration x) -> void
{
    interval_ = x;
}

auto Clock::getInterval() const -> Duration
{
    return interval_;
}

auto Clock::setMaxSteps(int x) -> void
{
    maxSteps_ = x;
}

auto Clock::getMaxSteps() const -> int
{
    return maxSteps_;
}

auto Clock::reset() -> void
{
    last_ = std::chrono::steady_clock::now();
    accumulate_ = Duration{};
}

auto Clock::tick() -> int
{
    const auto now = std::chrono::steady_clock::now();
    const auto elapsed = Duration{now - last_};
    last_ = now;
    return advance(elapsed);
}

auto Clock::advance(Duration elapsed) -> int
{
    accumulate_ += elapsed;

    auto steps = 0;
    while (accumulate_ >= interval_ && steps < maxSteps_)
    {
        accumulate_ -= interval_;
        ++steps;
    }

    // Drop any backlog beyond the cap so we don't perpetually chase it.
    if (accumulate_ >= interval_)
    {
        accumulate_ = Duration{};
    }

    return steps;
}

auto Clock::alpha() const -> float
{
    return accumulate_.toSeconds() / interval_.toSeconds();
}
