#pragma once

#include <string>

namespace bt::raylib
{
    /// @brief RAII owner of raylib's single global window: the constructor opens
    /// it (throwing if it cannot), the destructor closes it.
    ///
    /// Non-copyable and non-movable — there is exactly one global window, so a
    /// Window is a unique lifetime guard for it, never a value to copy or move. The
    /// frame and query calls (BeginDrawing, WindowShouldClose, ...) act on that
    /// global, so they live on the Renderer that owns the window rather than here.
    class Window
    {
    public:
        struct Traits
        {
            std::string title;
            int width;
            int height;
        };

        explicit Window(const Traits& traits);
        ~Window();

        Window(const Window&) = delete;
        auto operator=(const Window&) -> Window& = delete;
        Window(Window&&) = delete;
        auto operator=(Window&&) -> Window& = delete;
    };
}
