#pragma once

#include <game/Geo.hpp>

namespace bt::game
{
    /// @brief A compass heading: degrees clockwise from north, kept on [0, 360).
    ///
    /// The Geo angle convention made a type. Every value that enters — at
    /// construction or through turn arithmetic — is wrapped onto the canonical
    /// range, with a full turn (360) landing back on north (0), so a stored
    /// heading is in range by construction. Raw floats remain the type for turn
    /// deltas, which stay signed. Fully constexpr: the invariant holds in
    /// constant expressions too.
    class Heading
    {
    public:
        /// @brief North: 0 degrees.
        constexpr Heading() noexcept = default;

        /// @brief Wrap @p degrees onto [0, 360); 360 lands on 0.
        /// @param degrees The angle in degrees clockwise from north, any range.
        explicit constexpr Heading(float degrees) : degrees_{Geo::wrap360(degrees)}
        {
        }

        /// @brief The canonical angle in degrees clockwise from north.
        /// @return The wrapped angle, always in [0, 360).
        [[nodiscard]] constexpr auto degrees() const -> float
        {
            return degrees_;
        }

        /// @brief Turn by @p degrees (positive is clockwise), staying wrapped.
        /// @param degrees The signed turn to apply.
        constexpr auto operator+=(float degrees) -> Heading&
        {
            degrees_ = Geo::wrap360(degrees_ + degrees);
            return *this;
        }

        constexpr auto operator-=(float degrees) -> Heading&
        {
            return *this += -degrees;
        }

        /// @brief The shortest signed turn that brings this heading onto @p target.
        /// @param target The heading to turn onto.
        /// @return Degrees in [-180, 180); negative is a left turn.
        [[nodiscard]] constexpr auto turnTo(Heading target) const -> float
        {
            return Geo::wrap180(target.degrees_ - degrees_);
        }

        [[nodiscard]] auto operator==(const Heading& other) const -> bool = default;

    private:
        float degrees_{0.0F};
    };

    [[nodiscard]] constexpr auto operator+(Heading heading, float degrees) -> Heading
    {
        heading += degrees;
        return heading;
    }

    [[nodiscard]] constexpr auto operator-(Heading heading, float degrees) -> Heading
    {
        heading -= degrees;
        return heading;
    }
}
