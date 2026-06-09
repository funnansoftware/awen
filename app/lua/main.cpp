#include <raylib.h>
#include <filesystem>
#include <sol/sol.hpp>

import awen.core;
import awen.raylib;
import lua.property;

namespace
{
    struct ScriptNode
    {
        std::vector<ScriptNode> children;
        std::string type;
        sol::table properties;
    };

    using NodeBuilder = std::function<awen::raylib::Node*(awen::raylib::Node&, const ScriptNode&)>;
    using Registry = std::unordered_map<std::string, NodeBuilder>;

    [[nodiscard]] auto engine() -> awen::core::Engine&
    {
        static awen::core::Engine globalEngine;

        return globalEngine;
    }

    auto buildNode(awen::raylib::Node& parent, const ScriptNode& scriptNode, const Registry& registry) -> awen::raylib::Node*
    {
        const auto it = registry.find(scriptNode.type);

        if (it == std::ranges::end(registry))
        {
            throw std::runtime_error{"Unknown node type: " + scriptNode.type};
        }

        auto* created = it->second(parent, scriptNode);

        for (const auto& child : scriptNode.children)
        {
            buildNode(*created, child, registry);
        }

        return created;
    }

    auto makeWindow(sol::table table, const Registry& registry) -> void
    {
        const auto title = table["title"].get_or(std::string{"Awen"});
        const auto width = table["width"].get_or(1280);
        const auto height = table["height"].get_or(720);

        auto* window = engine().addChild<awen::raylib::Window>(awen::raylib::Window::Traits{
            .title = title,
            .width = width,
            .height = height,
        });

        auto* root = window->getRootNode();

        for (auto& [key, value] : table)
        {
            if (key.get_type() == sol::type::number && value.is<ScriptNode>())
            {
                buildNode(*root, value.as<ScriptNode>(), registry);
            }
        }
    }

    auto makeScriptNode(const std::string& type, sol::table table) -> ScriptNode
    {
        ScriptNode scriptNode;
        scriptNode.type = type;
        scriptNode.properties = table;

        for (auto& [key, value] : table)
        {
            if (key.get_type() == sol::type::number && value.is<ScriptNode>())
            {
                scriptNode.children.emplace_back(value.as<ScriptNode>());
            }
        }

        return scriptNode;
    }

    auto readVector2(const sol::table& table, std::string_view key) -> Vector2
    {
        sol::optional<sol::table> value = table[key];

        if (value.has_value())
        {
            return {.x = 0.0F, .y = 0.0F};
        }

        return {.x = value.value()["x"].get_or(0.0F), .y = value.value()["y"].get_or(0.0F)};
    }

    auto applyCommonProperties(awen::raylib::Node& node, const sol::table& properties) -> void
    {
        if (properties["position"].valid())
        {
            node.setPosition(readVector2(properties, "position"));
        }
    }

    auto makeRegistry() -> Registry
    {
        Registry registry;

        registry["Node"] = [](awen::raylib::Node& parent, const ScriptNode& scriptNode) -> awen::raylib::Node*
        {
            auto* node = parent.addNode<awen::raylib::Node>();

            applyCommonProperties(*node, scriptNode.properties);

            return node;
        };

        registry["Rectangle"] = [](awen::raylib::Node& parent, const ScriptNode& scriptNode) -> awen::raylib::Rectangle*
        {
            auto* rectangle = parent.addNode<awen::raylib::Rectangle>();

            // auto property = std::make_unique<lua::TemplatedProperty<float>>(
            //     "width", [&rectangle]() { return rectangle->getWidth(); }, [&rectangle](const float& value) { rectangle->setWidth(value); });

            // std::vector<std::unique_ptr<lua::Property>> properties;
            // properties.emplace_back(std::move(property));

            // for (auto& property : properties)
            // {
            // switch(property->getType())
            // {
            //     case lua::PropertyType::Float:
            //         {
            //             auto* float_property = static_cast<lua::TemplatedProperty<float>*>(property.get());
            //             float value = float_property->get();
            //             float_property->set(value + 10.0F);
            //         }
            //         break;
            // }

            // if (property->is<float>())
            // {
            //     auto* float_property = static_cast<lua::TemplatedProperty<float>*>(property.get());
            //     float value = float_property->get();
            //     float_property->set(value + 10.0F);
            // }

            // property->setValueAsString(lua.value());
            // property->setValue(lua.value());
            // }

            applyCommonProperties(*rectangle, scriptNode.properties);

            rectangle->setWidth(scriptNode.properties["width"].get_or(0.0F));
            rectangle->setHeight(scriptNode.properties["height"].get_or(0.0F));

            if (scriptNode.properties["color"].valid())
            {
                rectangle->setColor(scriptNode.properties["color"]);
            }

            return rectangle;
        };

        registry["Text"] = [](awen::raylib::Node& parent, const ScriptNode& scriptNode) -> awen::raylib::Text*
        {
            auto* text = parent.addNode<awen::raylib::Text>();

            applyCommonProperties(*text, scriptNode.properties);

            text->setText(scriptNode.properties["text"].get_or(std::string{}));

            return text;
        };

        return registry;
    }

    auto registerNodeFactory(sol::state& lua, const std::string& name) -> void
    {
        lua.set_function(name, [type = name](sol::table table) { return makeScriptNode(type, std::move(table)); });
    }
}

auto main() -> int
{
    try
    {
        sol::state lua;

        lua.open_libraries(sol::lib::base, sol::lib::table, sol::lib::string, sol::lib::math);

        lua.new_usertype<ScriptNode>("ScriptNode");

        const auto registry = makeRegistry();

        lua.set_function("Engine", engine);
        lua.set_function("Window", [&registry](sol::table table) { makeWindow(std::move(table), registry); });

        registerNodeFactory(lua, "Node");
        registerNodeFactory(lua, "Rectangle");
        registerNodeFactory(lua, "Text");

        lua["colors"] =
            lua.create_table_with("Red", awen::raylib::colors::Red, "Blue", awen::raylib::colors::Blue, "Green", awen::raylib::colors::Green);

        const auto scriptPath = std::filesystem::path{SOURCE_DIR} / "main.lua";

        lua.script_file(scriptPath.string());

        return engine().run();
    }
    catch (const sol::error& e)
    {
        std::cerr << "Lua error: " << e.what() << '\n';
        return EXIT_FAILURE;
    }
    catch (const std::exception& e)
    {
        std::cerr << "Error: " << e.what() << '\n';
        return EXIT_FAILURE;
    }
}