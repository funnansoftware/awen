#include <raylib/Window.hpp>

#include <stdexcept>

#include <raylib.h>

using bt::raylib::Window;

Window::Window(const Traits& traits)
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT);
    InitWindow(traits.width, traits.height, traits.title.c_str());

    if (!IsWindowReady())
    {
        throw std::runtime_error{"failed to create window"};
    }
}

Window::~Window()
{
    CloseWindow();
}
