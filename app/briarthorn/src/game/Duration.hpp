#pragma once

#include <chrono>
#include <compare>

namespace bt::game
{
    class Duration
    {
    public:
        using Seconds = std::chrono::duration<float>;

        Duration() noexcept = default;

        constexpr Duration(std::chrono::steady_clock::duration value) noexcept : duration_{value}
        {
        }

        [[nodiscard]] auto toSeconds() const -> Seconds;

        auto operator+=(Duration other) noexcept -> Duration&;
        auto operator-=(Duration other) noexcept -> Duration&;
        [[nodiscard]] auto operator<=>(Duration other) const noexcept -> std::partial_ordering;

    private:
        std::chrono::steady_clock::duration duration_{};
    };
}
