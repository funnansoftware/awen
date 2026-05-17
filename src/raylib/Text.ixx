module;

#include <raylib.h>
#include <string>
#include <typeinfo>

export module awen.raylib.text;
import awen.raylib.color;
import awen.raylib.node;

export namespace awen::raylib
{
    class Text : public Node
    {
    public:
        Text()
        {
            constexpr auto fontSize = 50;
            constexpr auto text = "Hello, Awen!";
            text_ = text;

            onRender(
                [this]
                {
                    //
                    DrawText(text_.c_str(), 0, 0, fontSize, ToRaylibColor(colors::Orange));
                });
        }

        Text(const Text&) = delete;
        auto operator=(const Text&) -> Text& = delete;

        Text(Text&&) noexcept = delete;
        auto operator=(Text&&) noexcept -> Text& = delete;

        ~Text() override = default;

    private:
        std::string text_;
    };
}