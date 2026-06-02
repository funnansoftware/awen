#include <filesystem>
#include <sol/sol.hpp>

namespace
{
    struct Node
    {
        std::vector<Node> children;
        std::string type;
        // std::string color;
        std::string text;
        float x;
        float y;
        float height;
        float width;
    };

    auto read_position(sol::table table, Node& node) -> void
    {
        sol::optional<sol::table> position = table["position"];

        if (position.has_value() == true)
        {
            node.x = position.value()["x"].get_or(0.0f);
            node.y = position.value()["y"].get_or(0.0f);
        }
    }

    auto make_rectangle(sol::table table) -> Node
    {
        Node node;
        node.type = "Rectangle";

        read_position(table, node);

        node.width = table["width"].get_or(0.0f);
        node.height = table["height"].get_or(0.0f);
        // node.color = table["color"].get_or(std::string{"white"});

        for (auto& [key, value] : table)
        {
            if (key.get_type() == sol::type::number && value.get_type() == sol::type::userdata)
            {
                node.children.emplace_back(value.as<Node>());
            }
        }

        return node;
    }
}

auto main() -> int
{
    sol::state lua;

    lua.new_usertype<Node>("NodeData");

    lua.set_function("Rectangle", make_rectangle);

    auto script_path = std::filesystem::path{SOURCE_DIR} / "main.lua";

    sol::object object = lua.script_file(script_path.string());

    Node rectangle = object.as<Node>();

    std::cout << "height: " << rectangle.height << "\n";

    return 0;
}