#include <array>

#include <QPointF>
#include <QQmlEngine>
#include <QString>

#include <gtest/gtest.h>

#include "Harness.h"

namespace
{
    // Every type the module ships; the loop below proves each one resolves and
    // instantiates from a bare import.
    constexpr auto Components = std::array{
        "ShapeArc",
        "ShapeGauge",
        "ShapeLink",
        "ShapePolygon",
        "ShapeReticle",
        "ShapeRing",
        "ShapeSector",
        "ShapeSparkline",
        "ShapeTicks",
    };
}

TEST(Shapes, SectorDefaultsToBoresightWedge)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeSector {
    width: 200
    height: 200
    readonly property point up: pointAt(0, 50)
}
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("angleAt").toDouble(), 0.0);
    EXPECT_DOUBLE_EQ(item->property("angleSpan").toDouble(), 60.0);

    const auto up = item->property("up").toPointF();
    EXPECT_NEAR(up.x(), 100.0, 1e-9);
    EXPECT_NEAR(up.y(), 50.0, 1e-9);
}

TEST(Shapes, EveryComponentInstantiates)
{
    auto engine = QQmlEngine{};
    for (const auto* name : Components)
    {
        const auto qml = QStringLiteral("import awen.shapes\n%1 { width: 100; height: 100 }")
                             .arg(QLatin1String{name})
                             .toUtf8();
        const auto item = load(engine, qml.constData());
        EXPECT_NE(item, nullptr) << name;
    }
}

TEST(ShapeArc, DefaultsToFullCircleInsideBounds)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeArc { width: 200; height: 200; strokeWidth: 4 }
)");
    ASSERT_NE(item, nullptr);

    EXPECT_DOUBLE_EQ(item->property("radius").toDouble(), 98.0);
    EXPECT_DOUBLE_EQ(item->property("angleStart").toDouble(), 0.0);
    EXPECT_DOUBLE_EQ(item->property("angleSweep").toDouble(), 360.0);
}

TEST(ShapeArc, PointAtMapsBearingsClockwiseFromUp)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import awen.shapes
ShapeArc {
    width: 200
    height: 200
    readonly property point up: pointAt(0, 50)
    readonly property point east: pointAt(90, 50)
    readonly property point down: pointAt(180, 50)
}
)");
    ASSERT_NE(item, nullptr);

    const auto up = item->property("up").toPointF();
    EXPECT_NEAR(up.x(), 100.0, 1e-9);
    EXPECT_NEAR(up.y(), 50.0, 1e-9);

    const auto east = item->property("east").toPointF();
    EXPECT_NEAR(east.x(), 150.0, 1e-9);
    EXPECT_NEAR(east.y(), 100.0, 1e-9);

    const auto down = item->property("down").toPointF();
    EXPECT_NEAR(down.x(), 100.0, 1e-9);
    EXPECT_NEAR(down.y(), 150.0, 1e-9);
}
