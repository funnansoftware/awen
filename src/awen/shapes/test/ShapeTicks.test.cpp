#include <QList>
#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

TEST(ShapeTicks, TwelveTicksByDefault)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTicks { width: 200; height: 200 }
)");
    ASSERT_NE(item, nullptr);

    const auto angles = item->property("tickAngles").value<QList<double>>();
    ASSERT_EQ(angles.size(), 12);
    EXPECT_EQ(angles.first(), 0.0);
    EXPECT_EQ(angles.last(), 330.0);
}

TEST(ShapeTicks, SuppressesTicksInsideTheGap)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTicks { width: 200; height: 200; gapAngle: 25; gapHalfAngle: 14.3239 }
)");
    ASSERT_NE(item, nullptr);

    // The gap spans (10.68, 39.32), so only the 30° tick vanishes.
    const auto angles = item->property("tickAngles").value<QList<double>>();
    EXPECT_EQ(angles.size(), 11);
    EXPECT_TRUE(angles.contains(0.0));
    EXPECT_FALSE(angles.contains(30.0));
}

TEST(ShapeTicks, SuppressionFollowsTheOnScreenBearing)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTicks {
    width: 200
    height: 200
    angleOffset: 90
    gapAngle: 25
    gapHalfAngle: 14.3239
}
)");
    ASSERT_NE(item, nullptr);

    // With the assembly rotated 90°, the fixed 300° tick lands in the gap.
    const auto angles = item->property("tickAngles").value<QList<double>>();
    EXPECT_EQ(angles.size(), 11);
    EXPECT_TRUE(angles.contains(30.0));
    EXPECT_FALSE(angles.contains(300.0));
}

TEST(ShapeTicks, NonPositiveStepMakesNoTicks)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTicks { width: 200; height: 200; stepAngle: 0 }
)");
    ASSERT_NE(item, nullptr);

    const auto angles = item->property("tickAngles");
    ASSERT_TRUE(angles.isValid());
    EXPECT_TRUE(angles.value<QList<double>>().isEmpty());
    EXPECT_TRUE(item->property("tickPath").toString().isEmpty());
}

TEST(ShapeTicks, PathDrawsOneSubpathPerTick)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTicks { width: 200; height: 200 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_EQ(item->property("tickPath").toString().count(QLatin1Char('M')), 12);
}

TEST(ShapeTicks, OffsetMovesTickPointsNotBearings)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTicks {
    width: 200
    height: 200
    angleOffset: 90
    readonly property point north: tickPoint(0, 100)
}
)");
    ASSERT_NE(item, nullptr);

    // The bearing list ignores the rotation; the drawn point applies it.
    const auto angles = item->property("tickAngles").value<QList<double>>();
    EXPECT_EQ(angles.size(), 12);
    EXPECT_TRUE(angles.contains(0.0));

    const auto north = item->property("north").toPointF();
    EXPECT_NEAR(north.x(), 200.0, 1e-9);
    EXPECT_NEAR(north.y(), 100.0, 1e-9);
}
