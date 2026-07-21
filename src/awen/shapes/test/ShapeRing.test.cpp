#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

TEST(ShapeRing, GapHalfAngleTracksFixedArcLength)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing { width: 200; height: 200; radius: 100; gapLength: 50 }
)");
    ASSERT_NE(item, nullptr);

    // 50 px of arc on a 100 px ring is 0.25 rad either side of the gap centre.
    EXPECT_NEAR(item->property("gapHalfAngle").toDouble(), 14.3239, 1e-3);
}

TEST(ShapeRing, ClampsOversizedGapToHalfTurn)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing { width: 200; height: 200; radius: 10; gapLength: 10000 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("gapHalfAngle").toDouble(), 180.0);
}

TEST(ShapeRing, GapCenterSitsOnTheRing)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing { width: 200; height: 200; radius: 100; gapLength: 50 }
)");
    ASSERT_NE(item, nullptr);

    auto center = item->property("gapCenter").toPointF();
    EXPECT_NEAR(center.x(), 100.0, 1e-9);
    EXPECT_NEAR(center.y(), 0.0, 1e-9);

    item->setProperty("gapAngle", 90.0);
    center = item->property("gapCenter").toPointF();
    EXPECT_NEAR(center.x(), 200.0, 1e-9);
    EXPECT_NEAR(center.y(), 100.0, 1e-9);
}

TEST(ShapeRing, InGapWrapsAroundNorth)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing {
    width: 200
    height: 200
    radius: 100
    gapLength: 50
    readonly property bool nearWrap: inGap(350)
    readonly property bool farWrap: inGap(340)
}
)");
    ASSERT_NE(item, nullptr);

    // The gap centred on 0 spans about ±14.32°, so 350 is inside and 340 out.
    EXPECT_TRUE(item->property("nearWrap").toBool());
    EXPECT_FALSE(item->property("farWrap").toBool());
}

TEST(ShapeRing, GapEdgeCountsAsOutside)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing {
    width: 200
    height: 200
    radius: 100
    gapLength: 50
    readonly property bool onEdge: inGap(gapHalfAngle)
    readonly property bool justInside: inGap(gapHalfAngle - 0.01)
}
)");
    ASSERT_NE(item, nullptr);

    // The comparison is strict, so the exact edge bearing stays visible.
    EXPECT_FALSE(item->property("onEdge").toBool());
    EXPECT_TRUE(item->property("justInside").toBool());
}

TEST(ShapeRing, ZeroRadiusHasNoGap)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing { width: 0; height: 0; gapLength: 50; strokeWidth: 0 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("gapHalfAngle").toDouble(), 0.0);
}

TEST(ShapeRing, DefaultRadiusKeepsStrokeInsideBounds)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeRing { width: 200; height: 200; strokeWidth: 4 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("radius").toDouble(), 98.0);
    EXPECT_DOUBLE_EQ(item->property("gapHalfAngle").toDouble(), 0.0);
}
