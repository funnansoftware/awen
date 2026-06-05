#include <raylib.h>
#include <filesystem>
#include <sol/sol.hpp>

import awen.core;
import awen.raylib;

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

    awen::core::Engine global_engine;

    [[nodiscard]] auto engine() -> awen::core::Engine&
    {
        return global_engine;
    }

    auto build_node(awen::raylib::Node& parent, const ScriptNode& script_node, const Registry& registry) -> awen::raylib::Node*
    {
        const auto it = registry.find(script_node.type);

        if (it == std::ranges::end(registry))
        {
            throw std::runtime_error{"Unknown node type: " + script_node.type};
        }

        auto* created = it->second(parent, script_node);

        for (const auto& child : script_node.children)
        {
            build_node(*created, child, registry);
        }

        return created;
    }

    auto make_window(sol::table table, const Registry& registry) -> void
    {
        const auto title = table["title"].get_or(std::string{"Awen"});
        const auto width = table["width"].get_or(1280);
        const auto height = table["height"].get_or(720);

        auto* window = global_engine.addChild<awen::raylib::Window>(awen::raylib::Window::Traits{
            .title = title,
            .width = width,
            .height = height,
        });

        auto* root = window->getRootNode();

        for (auto& [key, value] : table)
        {
            if (key.get_type() == sol::type::number && value.is<ScriptNode>())
            {
                build_node(*root, value.as<ScriptNode>(), registry);
            }
        }
    }

    auto make_script_node(const std::string& type, sol::table table) -> ScriptNode
    {
        ScriptNode script_node;
        script_node.type = type;
        script_node.properties = table;

        for (auto& [key, value] : table)
        {
            if (key.get_type() == sol::type::number && value.is<ScriptNode>() == true)
            {
                script_node.children.emplace_back(value.as<ScriptNode>());
            }
        }

        return script_node;
    }

    auto read_vector2(const sol::table& table, std::string_view key) -> Vector2
    {
        sol::optional<sol::table> value = table[key];

        if (value.has_value() == false)
        {
            return {.x = 0.0F, .y = 0.0F};
        }

        return {.x = value.value()["x"].get_or(0.0F), .y = value.value()["y"].get_or(0.0F)};
    }

    auto apply_common_properties(awen::raylib::Node& node, const sol::table& properties) -> void
    {
        if (properties["position"].valid() == true)
        {
            node.setPosition(read_vector2(properties, "position"));
        }
    }

    auto make_registry() -> Registry
    {
        Registry registry;

        registry["Node"] = [](awen::raylib::Node& parent, const ScriptNode& script_node) -> awen::raylib::Node*
        {
            auto* node = parent.addNode<awen::raylib::Node>();

            apply_common_properties(*node, script_node.properties);

            return node;
        };

        registry["Rectangle"] = [](awen::raylib::Node& parent, const ScriptNode& script_node) -> awen::raylib::Rectangle*
        {
            auto rectangle = parent.addNode<awen::raylib::Rectangle>();

            apply_common_properties(*rectangle, script_node.properties);

            rectangle->setWidth(script_node.properties["width"].get_or(0.0F));
            rectangle->setHeight(script_node.properties["height"].get_or(0.0F));

            if (script_node.properties["color"].valid() == true)
            {
                rectangle->setColor(script_node.properties["color"]);
            }

            return rectangle;
        };

        registry["Text"] = [](awen::raylib::Node& parent, const ScriptNode& script_node) -> awen::raylib::Text*
        {
            auto text = parent.addNode<awen::raylib::Text>();

            apply_common_properties(*text, script_node.properties);

            text->setText(script_node.properties["text"].get_or(std::string{}));

            return text;
        };

        return registry;
    }

    auto register_node_factory(sol::state& lua, std::string name) -> void
    {
        lua.set_function(name, [type = name](sol::table table) { return make_script_node(type, table); });
    }
}

auto main() -> int
{
    sol::state lua;

    lua.open_libraries(sol::lib::base, sol::lib::table, sol::lib::string, sol::lib::math);

    lua.new_usertype<ScriptNode>("ScriptNode");

    const auto registry = make_registry();

    lua.set_function("Engine", engine);
    lua.set_function("Window", [&registry](sol::table table) { make_window(table, registry); });

    register_node_factory(lua, "Node");
    register_node_factory(lua, "Rectangle");
    register_node_factory(lua, "Text");

    lua["colors"] = lua.create_table_with("Red", awen::raylib::colors::Red, "Blue", awen::raylib::colors::Blue, "Green", awen::raylib::colors::Green,
                                          "White", awen::raylib::colors::White, "Yellow", awen::raylib::colors::Yellow, "Magenta",
                                          awen::raylib::colors::Magenta, "Cyan", awen::raylib::colors::Cyan, "Orange", awen::raylib::colors::Orange);

    auto script_path = std::filesystem::path{SOURCE_DIR} / "main.lua";

    sol::object object = lua.script_file(script_path.string());

    return global_engine.run();
}