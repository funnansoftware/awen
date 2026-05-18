#include <raylib.h>
#include <cstdlib>
#include <format>
#include <magic_enum/magic_enum.hpp>
#include <tuple>
#include <typeinfo>
#include <variant>

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
    // pos->setRotation(45.0F);
    // pos->setScale({.x = 2.0F, .y = 2.0F});
    // NOLINTEND
    auto* text = pos->addNode<awen::raylib::Text>();

    rootNode->onEvents(
        [text](const auto& event)
        {
            if (std::holds_alternative<awen::raylib::EventKeyboard>(event))
            {
                const auto& keyboardEvent = std::get<awen::raylib::EventKeyboard>(event);

                if (keyboardEvent.type == awen::raylib::EventKeyboard::Type::Pressed)
                {
                    text->setText(std::format("Key {} pressed", magic_enum::enum_name(keyboardEvent.key)));
                }

                if (keyboardEvent.type == awen::raylib::EventKeyboard::Type::Released)
                {
                    text->setText(std::format("Key {} released", magic_enum::enum_name(keyboardEvent.key)));
                }
            }
        });

    return engine.run();
}