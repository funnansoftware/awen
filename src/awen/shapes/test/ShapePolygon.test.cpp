#include <QList>
#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

namespace
{
    constexpr auto Triangle = R"(
import QtQuick
import awen.shapes
ShapePolygon {
    width: 100
    height: 50
    points: [Qt.point(0, -0.5), Qt.point(0.5, 0.5), Qt.point(-0.5, 0.5)]
}
)";
}

TEST(ShapePolygon, PolylineClosesTheOutline)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, Triangle);
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_EQ(polyline.size(), 4);
    EXPECT_EQ(polyline.first(), polyline.last());
}

TEST(ShapePolygon, UnitBoxScalesUniformlyAboutTheCentre)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, Triangle);
    ASSERT_NE(item, nullptr);

    // The 100x50 item scales by its short side, so x spans 25..75, not 0..100.
    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_EQ(polyline.size(), 4);
    EXPECT_EQ(polyline[0], QPointF(50, 0));
    EXPECT_EQ(polyline[1], QPointF(75, 50));
    EXPECT_EQ(polyline[2], QPointF(25, 50));
}

TEST(ShapePolygon, PixelModePassesPointsThrough)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapePolygon {
    width: 100
    height: 50
    unitScale: false
    points: [Qt.point(10, 20), Qt.point(30, 40)]
}
)");
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_EQ(polyline.size(), 3);
    EXPECT_EQ(polyline[0], QPointF(10, 20));
    EXPECT_EQ(polyline[1], QPointF(30, 40));
    EXPECT_EQ(polyline[2], QPointF(10, 20));
}

TEST(ShapePolygon, EmptyPointsMakeAnEmptyPolyline)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapePolygon { width: 100; height: 50 }
)");
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline");
    ASSERT_TRUE(polyline.isValid());
    EXPECT_TRUE(polyline.value<QList<QPointF>>().isEmpty());
}
