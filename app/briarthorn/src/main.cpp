#include <cstdlib>
#include <exception>
#include <iostream>
#include <memory>

#include <Briarthorn.hpp>

// The graphics edge is chosen at build time: the CMake desktop presets define
// BRIARTHORN_RENDERER_QUICK (the qt manifest feature brings Qt Quick); the zig
// build and the android/emscripten presets render with raylib as before.
#if defined(BRIARTHORN_RENDERER_QUICK)
#include <quick/Application.hpp>
#else
#include <raylib/Renderer.hpp>
#endif

auto main(int argc, char** argv) -> int
try
{
    auto briarthorn = bt::Briarthorn{};

#if defined(BRIARTHORN_RENDERER_QUICK)
    // Qt owns the event loop: run() spins QGuiApplication and steps the
    // simulation once per presented frame.
    return bt::quick::run(briarthorn, argc, argv);
#else
    static_cast<void>(argc);
    static_cast<void>(argv);

    // Attach graphics (opens the window). Drop this line and the same Briarthorn
    // runs headless.
    briarthorn.setGraphics(std::make_unique<bt::raylib::Renderer>());

    briarthorn.run();

    return EXIT_SUCCESS;
#endif
}
catch (const std::exception& error)
{
    std::cerr << "briarthorn: " << error.what() << '\n';
    return EXIT_FAILURE;
}
catch (...)
{
    std::cerr << "briarthorn: unknown error\n";
    return EXIT_FAILURE;
}
