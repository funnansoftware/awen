#pragma once

#include <game/Vec2.hpp>

namespace bt::game
{
    class Heading;

    /// @brief The one home for the world's coordinate convention and the trig that
    /// derives from it.
    ///
    /// Position is in metres (1 px = 1 m); the origin is where
    /// ownship starts. +x is east, +y is south (screen-down), so north is -y.
    /// Angles — headings, bearings — are degrees clockwise from north (0 = N,
    /// 90 = E), kept in [0, 360). Everything that turns positions into angles, or
    /// angles into displacements, routes through here so the sign convention has
    /// one authoritative home. Ports `lib/sim/geo.dart`.
    class Geo
    {
    public:
        /// @brief Wrap an angle in degrees onto [0, 360) — the canonical heading range.
        ///
        /// Constexpr so Heading can hold its invariant in constant expressions;
        /// std::fmod isn't constexpr on our standard libraries (P0533), so the
        /// remainder is computed by exact shift-subtract instead: each doubling
        /// keeps a power-of-two multiple of 360 (exact), and subtracting a
        /// @c chunk in [magnitude/2, magnitude] is exact by Sterbenz's lemma —
        /// the result is bit-identical to std::fmod.
        /// @param deg The angle in degrees to wrap.
        /// @return The angle wrapped onto [0, 360).
        [[nodiscard]] static constexpr auto wrap360(float deg) -> float
        {
            auto magnitude = deg < 0.0F ? -deg : deg;
            while (magnitude >= DegreesPerCircle)
            {
                const auto half = magnitude / 2.0F; // exact: power-of-two scale
                auto chunk = DegreesPerCircle;
                while (chunk < half)
                {
                    chunk += chunk;
                }
                magnitude -= chunk;
            }
            const auto wrapped = deg < 0.0F ? -magnitude : magnitude;
            const auto canonical = wrapped < 0.0F ? wrapped + DegreesPerCircle : wrapped;
            // A tiny negative remainder rounds up to exactly 360 when added (the
            // float ulp near 360 is coarser), which would breach [0, 360) — fold
            // it onto 0, as the Dart original's trailing `% 360` did.
            return canonical >= DegreesPerCircle ? 0.0F : canonical;
        }

        /// @brief Wrap an angle in degrees onto [-180, 180) — the shortest-turn range.
        ///
        /// Negative is a left turn, positive a right turn.
        /// @param deg The angle in degrees to wrap.
        /// @return The angle wrapped onto [-180, 180).
        [[nodiscard]] static constexpr auto wrap180(float deg) -> float
        {
            return wrap360(deg + StraightAngle) - StraightAngle;
        }

        /// @brief The +x (east / screen-right) component of moving @p distance
        /// along @p heading.
        /// @param heading The heading to move along.
        /// @param distance The distance moved.
        /// @return The +x (east / screen-right) component of the displacement.
        [[nodiscard]] static auto offsetX(Heading heading, float distance) -> float;

        /// @brief The +y (south / screen-down) component of the same displacement.
        ///
        /// Negative when heading north, since north is -y.
        /// @param heading The heading to move along.
        /// @param distance The distance moved.
        /// @return The +y (south / screen-down) component of the displacement.
        [[nodiscard]] static auto offsetY(Heading heading, float distance) -> float;

        /// @brief The world displacement of moving @p distance along @p heading.
        /// @param heading The heading to move along.
        /// @param distance The distance moved.
        /// @return The world displacement as a Vec2.
        [[nodiscard]] static auto offset(Heading heading, float distance) -> Vec2;

    private:
        static constexpr auto DegreesPerCircle = 360.0F;
        static constexpr auto StraightAngle = 180.0F;
    };
}
