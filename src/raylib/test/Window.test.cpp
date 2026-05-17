#include <gtest/gtest.h>
#include <awen/test/Test.hpp>

import awen.raylib.window;

GRAPHICS_TEST(Window, Constructor)
{
    const awen::raylib::Window window{};
    EXPECT_TRUE(true);
}