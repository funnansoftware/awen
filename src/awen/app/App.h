#pragma once

namespace awen
{
    /// @brief Run the standard app bootstrap: engine, loadFromModule(@p uri, "Main"),
    /// exit on load failure, the AWEN_SMOKE_QUIT_MS test seam, then the event loop.
    /// awen_add_executable generates a main() calling this; a custom MAIN bootstrap
    /// should still end here so deploys keep the Qt Quick link and the test seam.
    /// @param uri The app's QML module URI; its root type must be Main.
    /// @return The event loop's exit code, or EXIT_FAILURE if Main failed to load.
    auto runApp(int argc, char** argv, const char* uri) -> int;
}
