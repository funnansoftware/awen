#include <raylib/Renderer.hpp>

#include <raylib.h>

#if defined(_WIN32)
#define GLFW_INCLUDE_NONE // don't let GLFW pull in OpenGL headers alongside raylib
#include <GLFW/glfw3.h>
#endif

#include <game/CommandBuffer.hpp>
#include <game/Entity.hpp>
#include <game/Geo.hpp>
#include <game/Vec2.hpp>
#include <game/World.hpp>

using bt::raylib::Renderer;

namespace
{
    // Marker geometry (metres): a small triangle pointing along the heading.
    constexpr auto MarkerNose = 12.0F;
    constexpr auto MarkerTail = 9.0F;
    constexpr auto MarkerTailAngle = 140.0F; // heading offset to each tail corner (deg)
    constexpr auto Half = 0.5F;

    [[nodiscard]] auto toScreen(bt::game::Vec2 world, bt::game::Vec2 camera, Vector2 center) -> Vector2
    {
        return Vector2{.x = center.x + (world.x - camera.x), .y = center.y + (world.y - camera.y)};
    }

    auto drawMarker(const bt::game::Entity& entity, bt::game::Vec2 camera, Vector2 center, Color color) -> void
    {
        const auto nose = entity.position + bt::game::Geo::offset(entity.heading, MarkerNose);
        const auto tailLeft = entity.position + bt::game::Geo::offset(entity.heading - MarkerTailAngle, MarkerTail);
        const auto tailRight = entity.position + bt::game::Geo::offset(entity.heading + MarkerTailAngle, MarkerTail);

        // Vertex order (nose, left, right) matches the fill winding raylib used
        // for the original hello-triangle in this screen's y-down space.
        DrawTriangle(toScreen(nose, camera, center), toScreen(tailLeft, camera, center), toScreen(tailRight, camera, center), color);
    }
}

Renderer::Renderer() : Renderer(Config{})
{
}

Renderer::Renderer(const Config& config) : window_{{.title = config.title, .width = config.width, .height = config.height}}
{
#if defined(_WIN32)
    installResizeRendering();
#endif
}

auto Renderer::shouldClose() const -> bool
{
    return WindowShouldClose();
}

auto Renderer::pollInput(bt::game::CommandBuffer& commands, bt::game::EntityId player) -> void
{
    if (player == bt::game::NullEntity)
    {
        return;
    }

    const auto forward = IsKeyDown(KEY_W) || IsKeyDown(KEY_UP);
    const auto backward = IsKeyDown(KEY_S) || IsKeyDown(KEY_DOWN);
    const auto left = IsKeyDown(KEY_A) || IsKeyDown(KEY_LEFT);
    const auto right = IsKeyDown(KEY_D) || IsKeyDown(KEY_RIGHT);
    const auto boost = IsKeyDown(KEY_LEFT_SHIFT) || IsKeyDown(KEY_RIGHT_SHIFT);

    commands.throttle(player, forward ? 1.0F : 0.0F);
    commands.brake(player, backward ? 1.0F : 0.0F);
    commands.steer(player, (right ? 1.0F : 0.0F) - (left ? 1.0F : 0.0F));
    commands.boost(player, boost ? 1.0F : 0.0F);
}

auto Renderer::draw(const bt::game::World& world) -> void
{
    BeginDrawing();
    ClearBackground(DARKGRAY);

    const auto center = Vector2{.x = static_cast<float>(GetScreenWidth()) * Half, .y = static_cast<float>(GetScreenHeight()) * Half};

    // Ownship-centred camera: the player (if any) sits at screen centre.
    auto camera = bt::game::Vec2{};
    if (const auto* found = world.find(world.getPlayer()); found != nullptr)
    {
        camera = found->position;
    }

    for (const auto& entity : world.entities())
    {
        const auto color = (entity.id == world.getPlayer()) ? ORANGE : SKYBLUE;
        drawMarker(entity, camera, center, color);
    }

    EndDrawing();
}

auto Renderer::render(const bt::game::World& world) -> void
{
#if defined(_WIN32)
    lastWorld_ = &world; // so the resize callbacks can repaint this same frame
#endif
    draw(world);
    PollInputEvents();
    SwapScreenBuffer();
}

#if defined(_WIN32)
auto Renderer::presentDuringResize() -> void
{
    // Called from GLFW's callbacks while the Win32 modal resize/move loop spins.
    // Repaint the last world at the current size and present it — deliberately
    // WITHOUT PollInputEvents(), which would re-enter glfwPollEvents() recursively.
    if (lastWorld_ == nullptr)
    {
        return;
    }
    draw(*lastWorld_);
    SwapScreenBuffer();
}

void Renderer::onWindowRefresh(GLFWwindow* window)
{
    if (auto* self = static_cast<Renderer*>(glfwGetWindowUserPointer(window)); self != nullptr)
    {
        self->presentDuringResize();
    }
}

void Renderer::onWindowResized(GLFWwindow* window, int width, int height)
{
    auto* self = static_cast<Renderer*>(glfwGetWindowUserPointer(window));
    if (self == nullptr)
    {
        return;
    }
    // Let raylib update its own viewport/screen size for the new dimensions...
    if (self->prevSizeCallback_ != nullptr)
    {
        self->prevSizeCallback_(window, width, height);
    }
    // ...then repaint at that new size so the window tracks the drag live.
    self->presentDuringResize();
}

auto Renderer::installResizeRendering() -> void
{
    // raylib made its GLFW window current during InitWindow; that is the handle
    // GLFW hands back here (raylib does not expose the GLFWwindow* directly).
    auto* window = glfwGetCurrentContext();
    if (window == nullptr)
    {
        return;
    }
    glfwSetWindowUserPointer(window, this);
    // raylib leaves the refresh callback unused; the size callback is raylib's, so
    // chain it (save the previous) rather than replace it.
    glfwSetWindowRefreshCallback(window, &Renderer::onWindowRefresh);
    prevSizeCallback_ = glfwSetWindowSizeCallback(window, &Renderer::onWindowResized);
}
#endif
