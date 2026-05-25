module;

#include <algorithm>
#include <chrono>
#include <cstdint>
#include <deque>
#include <format>

export module awen.raylib.textfps;
import awen.raylib.text;

export namespace awen::raylib
{
    class TextFPS : public Text
    {
    public:
        static constexpr auto DefaultRollingSize{200U};

        TextFPS()
        {
            onUpdate(
                [this](auto dt)
                {
                    frames_.emplace_back(dt);

                    if (std::size(frames_) > rollingSize_)
                    {
                        frames_.pop_front();
                    }

                    const auto sum = std::ranges::fold_left(frames_, std::chrono::duration<float>{}, std::plus<>{});
                    const auto avg = sum / static_cast<float>(std::size(frames_));
                    setText(std::format("FPS: {:.{}f}", 1.0F / avg.count(), 0));
                });
        }

        TextFPS(const TextFPS&) = delete;
        auto operator=(const TextFPS&) -> TextFPS& = delete;

        TextFPS(TextFPS&&) noexcept = delete;
        auto operator=(TextFPS&&) noexcept -> TextFPS& = delete;

        ~TextFPS() override = default;

        auto setRollingSize(std::uint32_t size) noexcept -> void
        {
            rollingSize_ = size;
        }

        [[nodiscard]] auto getRollingSize() const noexcept -> std::uint32_t
        {
            return rollingSize_;
        }

    private:
        std::deque<std::chrono::duration<float>> frames_;
        std::uint32_t rollingSize_{DefaultRollingSize};
    };
}