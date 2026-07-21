#include <QList>
#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

TEST(ShapeSparkline, AutoscaleUsesReferenceFloor)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; values: [1, 2, 10]; referenceValue: 16.7 }
)");
    ASSERT_NE(item, nullptr);

    // The peak sits under the floor, so the floor scales: 16.7 * 1.15.
    EXPECT_NEAR(item->property("scaleMax").toDouble(), 19.205, 1e-6);
    EXPECT_TRUE(item->property("referenceVisible").toBool());
}

TEST(ShapeSparkline, AutoscaleTracksThePeak)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; values: [1, 50]; referenceValue: 16.7 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_NEAR(item->property("scaleMax").toDouble(), 57.5, 1e-6);
}

TEST(ShapeSparkline, PinnedScaleWins)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; values: [1, 50]; maxValue: 30 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("scaleMax").toDouble(), 30.0);
}

TEST(ShapeSparkline, YForMapsLinearly)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline {
    width: 100
    height: 100
    maxValue: 20
    readonly property real atZero: yFor(0)
    readonly property real atMax: yFor(20)
    readonly property real atMiddle: yFor(10)
}
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("atZero").toDouble(), 100.0);
    EXPECT_DOUBLE_EQ(item->property("atMax").toDouble(), 0.0);
    EXPECT_DOUBLE_EQ(item->property("atMiddle").toDouble(), 50.0);
}

TEST(ShapeSparkline, EmptySeriesFallsBackToUnitScale)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline {
    width: 100
    height: 100
    readonly property real baseY: yFor(0)
}
)");
    ASSERT_NE(item, nullptr);

    // The fallback keeps yFor's divisor nonzero with no data and no reference.
    EXPECT_DOUBLE_EQ(item->property("scaleMax").toDouble(), 1.0);
    EXPECT_DOUBLE_EQ(item->property("baseY").toDouble(), 100.0);

    const auto trace = item->property("tracePolyline");
    ASSERT_TRUE(trace.isValid());
    EXPECT_TRUE(trace.value<QList<QPointF>>().isEmpty());
    const auto area = item->property("areaPolyline");
    ASSERT_TRUE(area.isValid());
    EXPECT_TRUE(area.value<QList<QPointF>>().isEmpty());
}

TEST(ShapeSparkline, TraceSpansTheWidthOldestFirst)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; maxValue: 10; values: [0, 10, 5] }
)");
    ASSERT_NE(item, nullptr);

    const auto trace = item->property("tracePolyline").value<QList<QPointF>>();
    ASSERT_EQ(trace.size(), 3);
    EXPECT_EQ(trace[0], QPointF(0, 100));
    EXPECT_EQ(trace[1], QPointF(50, 0));
    EXPECT_EQ(trace[2], QPointF(100, 50));
}

TEST(ShapeSparkline, AreaClosesToTheBaseline)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; maxValue: 10; values: [0, 10, 5] }
)");
    ASSERT_NE(item, nullptr);

    // The trace plus bottom-right, bottom-left and the closing first point.
    const auto area = item->property("areaPolyline").value<QList<QPointF>>();
    ASSERT_EQ(area.size(), 6);
    EXPECT_EQ(area[3], QPointF(100, 100));
    EXPECT_EQ(area[4], QPointF(0, 100));
    EXPECT_EQ(area[5], area[0]);
}

TEST(ShapeSparkline, SinglePointHasNoArea)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; maxValue: 10; values: [5] }
)");
    ASSERT_NE(item, nullptr);

    const auto trace = item->property("tracePolyline").value<QList<QPointF>>();
    ASSERT_EQ(trace.size(), 1);
    EXPECT_EQ(trace[0], QPointF(0, 50));
    EXPECT_TRUE(item->property("areaPolyline").value<QList<QPointF>>().isEmpty());
}

TEST(ShapeSparkline, ReferenceHidesOffScale)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSparkline { width: 100; height: 100; maxValue: 10; referenceValue: 16.7 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_FALSE(item->property("referenceVisible").toBool());

    // Releasing the pin autoscales above the reference, revealing it again.
    item->setProperty("maxValue", 0.0);
    EXPECT_TRUE(item->property("referenceVisible").toBool());
}
