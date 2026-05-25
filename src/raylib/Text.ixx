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
        static constexpr auto DefaultFontSize{20};

        Text()
        {
            onRender([this] { DrawText(text_.c_str(), 0, 0, fontSize_, ToRaylibColor(colors::Orange)); });
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

        auto setFontSize(int x) -> void
        {
            fontSize_ = x;
        }

        [[nodiscard]] auto getFontSize() const -> int
        {
            return fontSize_;
        }

    private:
        std::string text_;
        int fontSize_{DefaultFontSize};
    };
}