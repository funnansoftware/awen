#pragma once

#include <chrono>
#include <memory>
#include <vector>

#include <game/Clock.hpp>
#include <game/CommandBuffer.hpp>
#include <game/Duration.hpp>
#include <game/System.hpp>
#include <game/World.hpp>

namespace bt
{
    // The default fixed simulation step: 10 ms (i.e. 100 steps per second).
    inline constexpr auto DefaultStepInterval = game::Duration{std::chrono::milliseconds{10}};

    /// @brief The owning object of the app and its state: the world, the ordered
    /// systems, the fixed-timestep clock and the command buffer.
    ///
    /// It is renderer-free: it only steps the simulation, which is how tests (and
    /// any future server) drive it. Presentation and input live outside — the Qt
    /// Quick shell in bt::quick drives update() once per presented frame and reads
    /// the world through world().
    ///
    /// @code
    /// bt::Briarthorn briarthorn;
    /// bt::quick::run(briarthorn, argc, argv); // or just call update() in a loop
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

        /// @brief Restart the fixed-step clock's real-time accounting now.
        ///
        /// Call after slow start-up work (opening a window, loading assets) so the
        /// elapsed time isn't folded into the first update() as a catch-up burst.
        /// The Qt Quick shell does this once before its first frame.
        auto resetClock() -> void;

        /// @brief Accumulate the real time elapsed (via the chrono clock) since the
        /// last call and run every fixed step now due: for each, flush the command
        /// buffer then step every system.
        ///
        /// Zero, one, or several updates may run, so the sim holds its fixed rate no
        /// matter how often update() is called.
        auto update() -> void;

        [[nodiscard]] auto world() -> game::World&;
        [[nodiscard]] auto world() const -> const game::World&;
        [[nodiscard]] auto commands() -> game::CommandBuffer&;

    private:
        auto buildWorld() -> void;

        game::World world_;
        game::CommandBuffer commands_;
        std::vector<std::unique_ptr<game::System>> systems_;
        game::Clock clock_;
    };
}
