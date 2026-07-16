#include <cstdlib>
#include <exception>
#include <iostream>

#include <Briarthorn.hpp>
#include <quick/Application.hpp>

auto main(int argc, char** argv) -> int
try
{
    auto briarthorn = bt::Briarthorn{};

    // Qt owns the event loop: run() spins QGuiApplication and steps the
    // simulation once per presented frame.
    return bt::quick::run(briarthorn, argc, argv);
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
