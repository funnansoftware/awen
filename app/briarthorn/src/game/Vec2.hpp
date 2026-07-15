#pragma once

namespace bt::game
{
    /// @brief A 2D vector in world space (metres).
    ///
    /// The simulation carries its own vector type so `game/` stays free of raylib —
    /// the render layer converts it to a raylib Vector2 at the edge. Axes follow the
    /// Geo convention: +x is east, +y is south (screen-down).
    struct Vec2
    {
        float x{0.0F};
        float y{0.0F};

        [[nodiscard]] auto lengthSquared() const -> float;
        [[nodiscard]] auto length() const -> float;
    };

    [[nodiscard]] auto operator+(Vec2 a, Vec2 b) -> Vec2;
    [[nodiscard]] auto operator-(Vec2 a, Vec2 b) -> Vec2;
    [[nodiscard]] auto operator*(Vec2 v, float scale) -> Vec2;
}
