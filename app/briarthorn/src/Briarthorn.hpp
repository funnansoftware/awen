#pragma once

#include <chrono>
#include <memory>
#include <vector>

#include <game/Clock.hpp>
#include <game/CommandBuffer.hpp>
#include <game/Duration.hpp>
#include <game/Graphics.hpp>
#include <game/System.hpp>
#include <game/World.hpp>

namespace bt
{
    // The default fixed simulation step: 10 ms (i.e. 100 steps per second).
    inline constexpr auto DefaultStepInterval = game::Duration{std::chrono::milliseconds{10}};

    /// @brief The owning object of the app and its state: the world, the ordered
    /// systems, the fixed-timestep clock and the command buffer.
    ///
    /// It runs headless — the simulation steps with no graphics at all, which is how
    /// tests and any future server drive it — or drives an interactive loop once a
    /// graphics surface is attached. The surface is the abstract game::Graphics, so
    /// this object depends on no concrete renderer; main wires one in.
    ///
    /// @code
    /// bt::Briarthorn briarthorn;
    /// briarthorn.setGraphics(std::make_unique<bt::raylib::Renderer>()); // omit to stay headless
    /// briarthorn.run();
    /// @endcode
    class Briarthorn
    {
    public:
        explicit Briarthorn();

        /// @brief Set the fixed simulation step interval (e.g.
        /// `game::Duration{std::chrono::milliseconds{5}}`).
        ///
        /// Takes effect on the next step().
        /// @param step The fixed simulation step interval to set.
        auto setStepInterval(game::Duration step) -> void;

        /// @brief Attach the presentation-and-input surface run() drives.
        ///
        /// Until this is called the app is headless. Pass the concrete renderer
        /// (e.g. bt::raylib::Renderer); replacing an existing surface drops the
        /// old one first.
        /// @param graphics The surface to attach, or nullptr to go headless.
        auto setGraphics(std::unique_ptr<game::Graphics> graphics) -> void;

        /// @brief Restart the fixed-step clock's real-time accounting now.
        ///
        /// Call after slow start-up work (opening a window, loading assets) so the
        /// elapsed time isn't folded into the first update() as a catch-up burst.
        /// run() does this itself; frame loops owned by a framework (e.g. Qt)
        /// call it once before their first frame.
        auto resetClock() -> void;

        /// @brief Accumulate the real time elapsed (via the chrono clock) since the
        /// last call and run every fixed step now due: for each, flush the command
        /// buffer then step every system.
        ///
        /// Zero, one, or several updates may run, so the sim holds its fixed rate no
        /// matter how often update() is called. No graphics needed — the headless entry
        /// point.
        auto update() -> void;

        /// @brief Drive the loop until stopped: each iteration advances the
        /// simulation by the fixed updates now due (update(), on its own clock) and —
        /// when graphics are attached — polls input before and renders after.
        ///
        /// Runs headless too, with no window and no render. Ends when the window
        /// closes or stop() is called, and is safe to call again afterwards.
        auto run() -> void;

        /// @brief Ask run()'s loop to finish after the current iteration.
        ///
        /// The window's close button does this on its own; call it to end a headless
        /// run.
        auto stop() -> void;

        [[nodiscard]] auto world() -> game::World&;
        [[nodiscard]] auto world() const -> const game::World&;
        [[nodiscard]] auto commands() -> game::CommandBuffer&;

    private:
        auto buildWorld() -> void;

        game::World world_;
        game::CommandBuffer commands_;
        std::vector<std::unique_ptr<game::System>> systems_;
        game::Clock clock_;
        std::unique_ptr<game::Graphics> graphics_;
        bool running_{false};
    };
}
