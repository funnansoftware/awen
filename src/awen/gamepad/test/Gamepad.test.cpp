#include <GamepadTranslate.h>

#include <SDL3/SDL_events.h>
#include <SDL3/SDL_gamepad.h>

#include <gtest/gtest.h>

namespace
{
    using awen::decodeEvent;
    using awen::GamepadEventKind;
    using awen::normalizeAxis;

    // --- normalizeAxis --------------------------------------------------------

    TEST(NormalizeAxis, RestReadsZero)
    {
        EXPECT_DOUBLE_EQ(normalizeAxis(0), 0.0);
    }

    TEST(NormalizeAxis, PositiveExtremeIsOne)
    {
        EXPECT_DOUBLE_EQ(normalizeAxis(32767), 1.0);
    }

    TEST(NormalizeAxis, NegativeExtremeClampsToMinusOne)
    {
        // SDL's stick low end (-32768) is one step past the +32767 extreme; it must
        // clamp to -1 rather than landing at -1.00003.
        EXPECT_DOUBLE_EQ(normalizeAxis(-32768), -1.0);
        EXPECT_DOUBLE_EQ(normalizeAxis(-32767), -1.0);
    }

    TEST(NormalizeAxis, MidRangeIsProportional)
    {
        EXPECT_NEAR(normalizeAxis(16383), 0.5, 1e-4);
        EXPECT_NEAR(normalizeAxis(-16383), -0.5, 1e-4);
    }

    // --- decodeEvent ----------------------------------------------------------

    TEST(DecodeEvent, GamepadAddedIsConnected)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_GAMEPAD_ADDED;
        event.gdevice.which = 7;

        const auto decoded = decodeEvent(event);
        ASSERT_TRUE(decoded.has_value());
        EXPECT_EQ(decoded->kind, GamepadEventKind::Connected);
        EXPECT_EQ(decoded->deviceId, 7);
    }

    TEST(DecodeEvent, GamepadRemovedIsDisconnected)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_GAMEPAD_REMOVED;
        event.gdevice.which = 7;

        const auto decoded = decodeEvent(event);
        ASSERT_TRUE(decoded.has_value());
        EXPECT_EQ(decoded->kind, GamepadEventKind::Disconnected);
        EXPECT_EQ(decoded->deviceId, 7);
    }

    TEST(DecodeEvent, ButtonDownCarriesDeviceAndCode)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_GAMEPAD_BUTTON_DOWN;
        event.gbutton.which = 2;
        event.gbutton.button = static_cast<Uint8>(SDL_GAMEPAD_BUTTON_SOUTH);

        const auto decoded = decodeEvent(event);
        ASSERT_TRUE(decoded.has_value());
        EXPECT_EQ(decoded->kind, GamepadEventKind::ButtonPressed);
        EXPECT_EQ(decoded->deviceId, 2);
        EXPECT_EQ(decoded->code, static_cast<int>(SDL_GAMEPAD_BUTTON_SOUTH));
    }

    TEST(DecodeEvent, ButtonUpIsReleased)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_GAMEPAD_BUTTON_UP;
        event.gbutton.which = 2;
        event.gbutton.button = static_cast<Uint8>(SDL_GAMEPAD_BUTTON_NORTH);

        const auto decoded = decodeEvent(event);
        ASSERT_TRUE(decoded.has_value());
        EXPECT_EQ(decoded->kind, GamepadEventKind::ButtonReleased);
        EXPECT_EQ(decoded->code, static_cast<int>(SDL_GAMEPAD_BUTTON_NORTH));
    }

    TEST(DecodeEvent, AxisMotionNormalisesToOne)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_GAMEPAD_AXIS_MOTION;
        event.gaxis.which = 1;
        event.gaxis.axis = static_cast<Uint8>(SDL_GAMEPAD_AXIS_LEFTX);
        event.gaxis.value = static_cast<Sint16>(32767);

        const auto decoded = decodeEvent(event);
        ASSERT_TRUE(decoded.has_value());
        EXPECT_EQ(decoded->kind, GamepadEventKind::AxisMotion);
        EXPECT_EQ(decoded->deviceId, 1);
        EXPECT_EQ(decoded->code, static_cast<int>(SDL_GAMEPAD_AXIS_LEFTX));
        EXPECT_DOUBLE_EQ(decoded->value, 1.0);
    }

    TEST(DecodeEvent, AxisMotionClampsNegativeExtreme)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_GAMEPAD_AXIS_MOTION;
        event.gaxis.which = 1;
        event.gaxis.axis = static_cast<Uint8>(SDL_GAMEPAD_AXIS_LEFTY);
        event.gaxis.value = static_cast<Sint16>(-32768);

        const auto decoded = decodeEvent(event);
        ASSERT_TRUE(decoded.has_value());
        EXPECT_DOUBLE_EQ(decoded->value, -1.0);
    }

    TEST(DecodeEvent, QuitEventIsIgnored)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_QUIT;

        EXPECT_FALSE(decodeEvent(event).has_value());
    }

    TEST(DecodeEvent, KeyboardEventIsIgnored)
    {
        auto event = SDL_Event{};
        event.type = SDL_EVENT_KEY_DOWN;

        EXPECT_FALSE(decodeEvent(event).has_value());
    }
}
