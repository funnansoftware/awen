#pragma once

#include <chrono>

#include <game/Duration.hpp>

namespace bt::game
{
    // Avoid spiral of death in the fixed-timestep simulation by using a cap on the maximum number of steps per frame.
    inline constexpr auto DefaultMaxSteps = 8;

    class Clock
    {
    public:
        auto setInterval(Duration x) -> void;
        [[nodiscard]] auto getInterval() const -> Duration;

        auto setMaxSteps(int x) -> void;
        [[nodiscard]] auto getMaxSteps() const -> int;

        /// @brief Re-stamp "now" and drop any banked time — call it the moment
        /// real-time stepping begins (e.g. after the window opens), so slow
        /// start-up work is not folded into the first frame as a catch-up burst.
        auto reset() -> void;

        /// @brief Sample the monotonic clock and fold the elapsed real time into
        /// the accumulator.
        /// @return How many fixed steps are now due (0..maxSteps).
        auto tick() -> int;

        /// @brief Fold an explicit elapsed duration in.
        ///
        /// The testable core of tick(), and the seam for driving the clock from a
        /// fixed source in tests.
        /// @param elapsed The explicit elapsed duration to fold in.
        /// @return How many fixed steps are now due (0..maxSteps).
        auto advance(Duration elapsed) -> int;

        /// @brief How far (0..1) into the next step the accumulator sits.
        /// @return The blend factor a renderer can use to interpolate between the
        /// last two states.
        [[nodiscard]] auto alpha() const -> float;

    private:
        Duration interval_;
        Duration accumulate_;
        std::chrono::steady_clock::time_point last_;
        int maxSteps_{DefaultMaxSteps};
    };
}
