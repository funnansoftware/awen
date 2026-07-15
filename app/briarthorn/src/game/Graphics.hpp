#pragma once

#include <game/Entity.hpp>

namespace bt::game
{
    class World;
    class CommandBuffer;

    /// @brief The optional presentation-and-input surface a Briarthorn can be given.
    ///
    /// A headless Briarthorn has none — it just steps the simulation — while an
    /// interactive one is handed a concrete surface (bt::raylib::Renderer) that
    /// opens a window, draws the world and reads device input. Kept abstract here
    /// so the game core never depends on raylib; only the app wires the concrete
    /// implementation in (briarthorn.graphics = std::make_unique<...>()).
    class Graphics
    {
    public:
        Graphics() = default;
        virtual ~Graphics() = default;
        Graphics(const Graphics&) = delete;
        auto operator=(const Graphics&) -> Graphics& = delete;
        Graphics(Graphics&&) noexcept = delete;
        auto operator=(Graphics&&) noexcept -> Graphics& = delete;

        /// @brief Whether the surface wants to close (e.g. the window's close button).
        /// @return Whether the surface wants to close.
        [[nodiscard]] virtual auto shouldClose() const -> bool = 0;

        /// @brief Read this frame's device input and record it for @p player as commands.
        /// @param commands The command buffer to record input commands into.
        /// @param player The id of the entity to record input for.
        virtual auto pollInput(CommandBuffer& commands, EntityId player) -> void = 0;

        /// @brief Draw the world for this frame.
        /// @param world The world to draw.
        virtual auto render(const World& world) -> void = 0;
    };
}
