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

        auto setText(std::string_view text) -> void
        {
            text_ = text;
        }

        [[nodiscard]] auto getText() const noexcept -> std::string_view
        {
            return text_;
        }

    private:
        std::string text_;
    };
}