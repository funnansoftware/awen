#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

TEST(ShapeGauge, DefaultsToBottomOpenGauge)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeGauge { width: 200; height: 200 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("angleStart").toDouble(), 225.0);
    EXPECT_DOUBLE_EQ(item->property("angleSweep").toDouble(), 270.0);
    EXPECT_DOUBLE_EQ(item->property("fillSweep").toDouble(), 0.0);
}

TEST(ShapeGauge, FillSweepClampsValue)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeGauge { width: 200; height: 200; value: -1 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("fillSweep").toDouble(), 0.0);

    item->setProperty("value", 2.0);
    EXPECT_DOUBLE_EQ(item->property("fillSweep").toDouble(), 270.0);

    item->setProperty("value", 0.5);
    EXPECT_DOUBLE_EQ(item->property("fillSweep").toDouble(), 135.0);
}

TEST(ShapeGauge, FillHidesAtZeroValue)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeGauge { width: 200; height: 200 }
)");
    ASSERT_NE(item, nullptr);

    // A zero-length arc with a round cap would paint a stray dot, so the fill
    // reports invisible at rest.
    EXPECT_FALSE(item->property("fillVisible").toBool());

    item->setProperty("value", 0.1);
    EXPECT_TRUE(item->property("fillVisible").toBool());
}

TEST(ShapeGauge, FillEndTracksValue)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeGauge { width: 200; height: 200; radius: 100; value: 0.5 }
)");
    ASSERT_NE(item, nullptr);

    // 225 + 135 wraps to bearing 0 — straight up from the centre.
    const auto end = item->property("fillEnd").toPointF();
    EXPECT_NEAR(end.x(), 100.0, 1e-9);
    EXPECT_NEAR(end.y(), 0.0, 1e-9);
}
