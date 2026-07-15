#pragma once

#include <string>

#include <game/Entity.hpp>
#include <game/Graphics.hpp>

#include <raylib/Window.hpp>

#if defined(_WIN32)
// Forward-declared so the GLFW resize hooks can be declared here without pulling
// the GLFW headers into every consumer; Renderer.cpp includes <GLFW/glfw3.h>.
struct GLFWwindow;
#endif

namespace bt::game
{
    class World;
    class CommandBuffer;
}

namespace bt::raylib
{
    inline constexpr auto DefaultWindowWidth = 800;
    inline constexpr auto DefaultWindowHeight = 600;

    /// @brief The raylib graphics surface attached to a Briarthorn.
    ///
    /// It owns the window and implements bt::game::Graphics: it presents the world
    /// (ownship-centred, 1 px = 1 m) and reads the keyboard into the command buffer.
    /// The concrete `graphics` a headless Briarthorn does without.
    class Renderer : public bt::game::Graphics
    {
    public:
        struct Config
        {
            std::string title = "briarthorn";
            int width = DefaultWindowWidth;
            int height = DefaultWindowHeight;
        };

        Renderer();
        explicit Renderer(const Config& config);

        [[nodiscard]] auto shouldClose() const -> bool override;
        auto pollInput(bt::game::CommandBuffer& commands, bt::game::EntityId player) -> void override;
        auto render(const bt::game::World& world) -> void override;

    private:
        /// @brief Draw the world for one frame — no buffer swap, no input poll.
        /// @param world The world to draw.
        auto draw(const bt::game::World& world) -> void;

        Window window_;

#if defined(_WIN32)
        // Keep painting during the Win32 modal resize/move loop. That loop blocks
        // the main loop inside glfwPollEvents(), but GLFW still dispatches size and
        // paint messages to these callbacks, so we repaint from them — presenting
        // without polling input (which would re-enter the event loop).
        auto installResizeRendering() -> void;
        auto presentDuringResize() -> void;
        static void onWindowRefresh(GLFWwindow* window);
        static void onWindowResized(GLFWwindow* window, int width, int height);

        // GLFW's window-size callback signature (GLFWwindowsizefun), spelled out so
        // this header needn't include <GLFW/glfw3.h>. Holds raylib's own size
        // callback, which onWindowResized chains before repainting.
        using GlfwSizeCallback = void (*)(GLFWwindow*, int, int);

        const bt::game::World* lastWorld_ = nullptr;
        GlfwSizeCallback prevSizeCallback_ = nullptr;
#endif
    };
}
