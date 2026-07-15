#pragma once

namespace bt
{
    class Briarthorn;
}

namespace bt::quick
{
    /// @brief Run @p briarthorn under a Qt Quick shell until the window closes.
    ///
    /// Owns the QGuiApplication and the QML engine: loads Main.qml from the
    /// briarthorn.quick module, steps the simulation once per presented frame
    /// (vsync-locked, like the raylib loop), and routes the window's keyboard
    /// input into the command buffer.
    /// @param briarthorn The app object to drive; stays headless-capable, this
    /// only calls its public update()/world()/commands() API.
    /// @param argc argv Forwarded to QGuiApplication.
    /// @return The Qt event loop's exit code.
    auto run(Briarthorn& briarthorn, int argc, char** argv) -> int;
}
