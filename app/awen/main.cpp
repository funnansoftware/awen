#include <raylib.h>
#include <cstdlib>
#include <tuple>
#include <typeinfo>

import awen.core;
import awen.raylib;

using awen::raylib::Window;

auto main() -> int
{
    constexpr auto width{1280};
    constexpr auto height{720};

    awen::core::Engine engine;

    auto* window = engine.addChild<Window>(Window::Traits{
        .title = "Awen",
        .width = width,
        .height = height,
    });

    auto* rootNode = window->getRootNode();
    auto* pos = rootNode->addNode<awen::raylib::Node>();

    // NOLINTBEGIN
    pos->setPosition({.x = width / 2.0F, .y = height / 2.0F});
    pos->setRotation(45.0F);
    pos->setScale({.x = 2.0F, .y = 2.0F});
    // NOLINTEND
    std::ignore = pos->addNode<awen::raylib::Text>();

    return engine.run();
}