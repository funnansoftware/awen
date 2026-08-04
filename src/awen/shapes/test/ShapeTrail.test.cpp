#include <QList>
#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

namespace
{
    /// @brief Pushes one position sample through the trail's ring.
    auto record(QObject& trail, double x, double y) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&trail, "record", Q_ARG(double, x), Q_ARG(double, y)));
    }

    /// @brief Reads the plotted centre of one dot in item pixels.
    auto dotCenter(QObject& trail, int index) -> QPointF
    {
        auto center = QPointF{};
        EXPECT_TRUE(QMetaObject::invokeMethod(&trail, "dotCenter", Q_RETURN_ARG(QPointF, center), Q_ARG(int, index)));
        return center;
    }
}

TEST(ShapeTrail, RecordKeepsOldestFirstWithinCapacity)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTrail { width: 100; height: 100; capacity: 3 }
)");
    ASSERT_NE(item, nullptr);

    record(*item, 1, 0);
    record(*item, 2, 0);
    record(*item, 3, 0);
    auto points = item->property("points").value<QList<QPointF>>();
    ASSERT_EQ(points.size(), 3);
    EXPECT_EQ(points[0], QPointF(1, 0));
    EXPECT_EQ(points[2], QPointF(3, 0));

    // A fourth sample rolls the ring: the oldest drops, the newest appends.
    record(*item, 4, 0);
    points = item->property("points").value<QList<QPointF>>();
    ASSERT_EQ(points.size(), 3);
    EXPECT_EQ(points[0], QPointF(2, 0));
    EXPECT_EQ(points[2], QPointF(4, 0));
}

TEST(ShapeTrail, DotsPlotScaledOffsetsFromCurrentAboutTheAnchor)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTrail {
    width: 100
    height: 100
    positionScale: 0.5
    currentX: 1000
    currentY: 2000
}
)");
    ASSERT_NE(item, nullptr);

    // 40 units astern and 20 left of the current position, at half scale.
    record(*item, 960, 1980);
    record(*item, 1000, 2000);
    EXPECT_EQ(dotCenter(*item, 0), QPointF(50 - 20, 50 - 10));
    EXPECT_EQ(dotCenter(*item, 1), QPointF(50, 50));
}

TEST(ShapeTrail, DotsFollowCurrentBetweenSamples)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTrail { width: 100; height: 100 }
)");
    ASSERT_NE(item, nullptr);

    record(*item, 10, 0);

    // The wake hangs off the live position, so moving it shifts every dot.
    item->setProperty("currentX", 10.0);
    EXPECT_EQ(dotCenter(*item, 0), QPointF(50, 50));

    item->setProperty("currentX", 30.0);
    EXPECT_EQ(dotCenter(*item, 0), QPointF(30, 50));
}

TEST(ShapeTrail, ResetDropsTheHistory)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeTrail { width: 100; height: 100 }
)");
    ASSERT_NE(item, nullptr);

    record(*item, 1, 1);
    record(*item, 2, 2);
    EXPECT_TRUE(QMetaObject::invokeMethod(item.get(), "reset"));
    EXPECT_TRUE(item->property("points").value<QList<QPointF>>().isEmpty());
}
