#include <QList>
#include <QPointF>
#include <QQmlEngine>

#include <gtest/gtest.h>

#include "Harness.h"

TEST(ShapeLink, DefaultControlsGiveHorizontalTangents)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeLink { from: Qt.point(0, 0); to: Qt.point(100, 40) }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_EQ(item->property("fromControl").toPointF(), QPointF(45, 0));
    EXPECT_EQ(item->property("toControl").toPointF(), QPointF(55, 40));
}

TEST(ShapeLink, ControlOverrideSticks)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeLink { from: Qt.point(0, 0); to: Qt.point(100, 40); toControl: Qt.point(1, 2) }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_EQ(item->property("toControl").toPointF(), QPointF(1, 2));
}

TEST(ShapeLink, ArrowheadAlignsWithArrivalTangent)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeLink { from: Qt.point(0, 0); to: Qt.point(100, 40); arrowhead: true }
)");
    ASSERT_NE(item, nullptr);

    // Arrival runs +x from toControl (55, 40), so the chevron opens backward
    // from the tip with arrowSize depth and two-thirds half-width.
    const auto chevron = item->property("arrowPolyline").value<QList<QPointF>>();
    ASSERT_EQ(chevron.size(), 3);
    EXPECT_NEAR(chevron[0].x(), 94.0, 1e-9);
    EXPECT_NEAR(chevron[0].y(), 44.0, 1e-9);
    EXPECT_EQ(chevron[1], QPointF(100, 40));
    EXPECT_NEAR(chevron[2].x(), 94.0, 1e-9);
    EXPECT_NEAR(chevron[2].y(), 36.0, 1e-9);
}

TEST(ShapeLink, NoArrowheadNoChevron)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeLink { from: Qt.point(0, 0); to: Qt.point(100, 40) }
)");
    ASSERT_NE(item, nullptr);

    const auto chevron = item->property("arrowPolyline");
    ASSERT_TRUE(chevron.isValid());
    EXPECT_TRUE(chevron.value<QList<QPointF>>().isEmpty());
}

TEST(ShapeLink, VerticalLinkKeepsItsArrowhead)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeLink { from: Qt.point(50, 0); to: Qt.point(50, 100); arrowhead: true }
)");
    ASSERT_NE(item, nullptr);

    // The default controls collapse onto the endpoints here, so the chevron
    // falls back to the chord direction — straight down.
    const auto chevron = item->property("arrowPolyline").value<QList<QPointF>>();
    ASSERT_EQ(chevron.size(), 3);
    EXPECT_NEAR(chevron[0].x(), 46.0, 1e-9);
    EXPECT_NEAR(chevron[0].y(), 94.0, 1e-9);
    EXPECT_EQ(chevron[1], QPointF(50, 100));
    EXPECT_NEAR(chevron[2].x(), 54.0, 1e-9);
    EXPECT_NEAR(chevron[2].y(), 94.0, 1e-9);
}

TEST(ShapeLink, DegenerateLinkDrawsNoChevron)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeLink { from: Qt.point(50, 50); to: Qt.point(50, 50); arrowhead: true }
)");
    ASSERT_NE(item, nullptr);

    const auto chevron = item->property("arrowPolyline");
    ASSERT_TRUE(chevron.isValid());
    EXPECT_TRUE(chevron.value<QList<QPointF>>().isEmpty());
}
