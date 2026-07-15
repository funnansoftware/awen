#pragma once

#include <QtQml/qqmlregistration.h>
#include <QObject>
#include <QSet>

#include <game/World.hpp>

namespace bt
{
    class Briarthorn;
}

namespace bt::quick
{
    /// @brief The QML-facing handle on the running Briarthorn: WorldView reads the
    /// world through it, the window's key events accumulate in it, and frame()
    /// (connected to the window's frameSwapped) turns both into one simulation step.
    ///
    /// The Qt analog of the raylib loop body: pollInput (the held-key set applied
    /// to the command buffer), update, then notify the view to repaint.
    class GameController : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("created in C++ (quick::run) and injected as the window's game property")

    public:
        explicit GameController(Briarthorn& briarthorn, QObject* parent = nullptr);

        [[nodiscard]] auto world() const -> const game::World&;

        /// @brief Record a key transition from the view's key events.
        /// @param key The Qt::Key that changed.
        /// @param down Whether the key is now held.
        auto setKey(int key, bool down) -> void;

        /// @brief Drop every held key (the view lost focus, so releases may never arrive).
        auto releaseKeys() -> void;

        /// @brief One frame: apply the held keys to the command buffer as steering
        /// intent (mirrors the raylib pollInput mapping), advance the simulation by
        /// the fixed steps now due, and emit stepped() for the view.
        auto frame() -> void;

    signals:
        /// @brief The simulation advanced; the view repaints on this.
        void stepped();

    private:
        Briarthorn& briarthorn_;
        QSet<int> held_;
    };
}
