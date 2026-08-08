#include <algorithm>
#include <cmath>
#include <numbers>
#include <vector>

#include <QList>
#include <QPointF>
#include <QQmlEngine>
#include <QString>

#include <gtest/gtest.h>

#include "Harness.h"

namespace
{
    constexpr auto Pi = std::numbers::pi;

    /// @brief One occluding disc, in source units about the apex.
    struct Disc
    {
        double x{0};
        double y{0};
        double r{0};
    };

    /// @brief The blocking rule under test, restated independently: whether a
    /// segment of the given length along bearing (ux, uy) from the origin
    /// passes within r of any disc centre — Geo.lineOfSight's closest-point
    /// test with the observer at the origin.
    auto blocked(double ux, double uy, double length, const std::vector<Disc>& discs) -> bool
    {
        for (const auto& disc : discs)
        {
            const auto bx = ux * length;
            const auto by = uy * length;
            const auto len2 = bx * bx + by * by;
            const auto t = len2 > 0 ? std::clamp((disc.x * bx + disc.y * by) / len2, 0.0, 1.0) : 0.0;
            const auto nx = t * bx - disc.x;
            const auto ny = t * by - disc.y;
            if (nx * nx + ny * ny <= disc.r * disc.r)
            {
                return true;
            }
        }
        return false;
    }

    /// @brief Shortest angular distance between two bearings, degrees.
    auto angularDistance(double a, double b) -> double
    {
        return std::abs(std::fmod(a - b + 540.0, 360.0) - 180.0);
    }

    /// @brief Radius of a polyline vertex about the (200, 200) apex, in px.
    auto radiusOf(const QPointF& p) -> double
    {
        return std::hypot(p.x() - 200, p.y() - 200);
    }

    /// @brief Bearing of a polyline vertex about the apex, degrees clockwise
    /// from up, in (-180, 180].
    auto bearingOf(const QPointF& p) -> double
    {
        return std::atan2(p.x() - 200, -(p.y() - 200)) * 180 / Pi;
    }

    /// @brief The vertex angularly nearest a bearing, skipping the first and
    /// last points (the apex, or the closing duplicate on a full circle).
    auto vertexAt(const QList<QPointF>& polyline, double bearing) -> QPointF
    {
        auto best = polyline[1];
        auto bestOff = 360.0;
        for (auto i = 1; i < polyline.size() - 1; ++i)
        {
            const auto off = angularDistance(bearingOf(polyline[i]), bearing);
            if (off < bestOff)
            {
                bestOff = off;
                best = polyline[i];
            }
        }
        return best;
    }

    // A 90-degree north wedge reaching 100 px at scale 1, apex at (200, 200).
    constexpr auto Wedge = R"(
import QtQuick
import awen.shapes
ShapeSectorOccluded {
    width: 400
    height: 400
    angleAt: 0
    angleSpan: 90
    radius: 100
    positionScale: 1
    occluders: %1
}
)";

    /// @brief Loads the wedge harness over the given occluders line.
    auto loadWedge(QQmlEngine& engine, const char* occluders) -> std::unique_ptr<QObject>
    {
        return load(engine, QString{Wedge}.arg(occluders).toUtf8().constData());
    }
}

TEST(ShapeSectorOccluded, ClearWedgeSweepsTheFullSector)
{
    auto engine = QQmlEngine{};
    const auto item = loadWedge(engine, "[]");
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_GE(polyline.size(), 3);
    EXPECT_EQ(polyline.first(), QPointF(200, 200));
    EXPECT_EQ(polyline.first(), polyline.last());
    for (auto i = 1; i < polyline.size() - 1; ++i)
    {
        EXPECT_NEAR(radiusOf(polyline[i]), 100, 1e-6);
    }
    EXPECT_NEAR(bearingOf(polyline[1]), -45, 1e-6);
    EXPECT_NEAR(bearingOf(polyline[polyline.size() - 2]), 45, 1e-6);
    // The rim is swept, not chorded across: two edge rays alone would satisfy
    // every assertion above while cutting half the wedge's area.
    for (auto i = 2; i < polyline.size() - 1; ++i)
    {
        EXPECT_LE(bearingOf(polyline[i]) - bearingOf(polyline[i - 1]), 3 + 1e-6);
    }
}

TEST(ShapeSectorOccluded, RayPitchFollowsStepDeg)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeSectorOccluded {
    width: 400
    height: 400
    angleAt: 0
    angleSpan: 90
    radius: 100
    positionScale: 1
    stepDeg: 10
}
)");
    ASSERT_NE(item, nullptr);

    // A clear 90-degree wedge at a 10-degree pitch: both edges plus the eight
    // steps between them, and no gap wider than the pitch asked for.
    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_EQ(polyline.size(), 12);
    for (auto i = 2; i < polyline.size() - 1; ++i)
    {
        EXPECT_NEAR(bearingOf(polyline[i]) - bearingOf(polyline[i - 1]), 10, 1e-6);
    }
}

TEST(ShapeSectorOccluded, PillarBitesToItsNearFaceAndTangents)
{
    auto engine = QQmlEngine{};
    // Dead ahead at 50 with radius 10: tangents at asin(10/50) = 11.537
    // degrees, tangent length sqrt(2400), near face at 40.
    const auto item = loadWedge(engine, "[{ x: 0, y: -50, r: 10 }]");
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_GE(polyline.size(), 3);
    const auto alpha = std::asin(0.2) * 180 / Pi;
    EXPECT_NEAR(radiusOf(vertexAt(polyline, 0)), 40, 1e-6);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, -alpha)), std::sqrt(2400.0), 1e-3);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, alpha)), std::sqrt(2400.0), 1e-3);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, -30)), 100, 1e-6);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, 30)), 100, 1e-6);
}

TEST(ShapeSectorOccluded, TangentPadHoldsTheShadowEdgeRadial)
{
    auto engine = QQmlEngine{};
    const auto item = loadWedge(engine, "[{ x: 0, y: -50, r: 10 }]");
    ASSERT_NE(item, nullptr);

    // Each shadow edge is a pair of rays a twentieth of a degree apart: the
    // tangent itself at the tangent length, and one just outside it back at
    // full reach. Without the outer ray the edge slants to the next uniform
    // ray up to stepDeg away and the shadow detaches from its pillar.
    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    const auto alpha = std::asin(0.2) * 180 / Pi;
    for (const auto side : {-1.0, 1.0})
    {
        const auto tangent = vertexAt(polyline, side * alpha);
        const auto pad = vertexAt(polyline, side * (alpha + 0.05));
        EXPECT_NEAR(radiusOf(tangent), std::sqrt(2400.0), 1e-3);
        EXPECT_NEAR(radiusOf(pad), 100, 1e-6);
        EXPECT_NEAR(angularDistance(bearingOf(tangent), bearingOf(pad)), 0.05, 1e-6);
    }
}

TEST(ShapeSectorOccluded, OccludersMapThroughTheApexAndScale)
{
    auto engine = QQmlEngine{};
    // Apex off the origin at half scale, so neither the source-unit offset
    // nor the px conversion can cancel: reach is 100 px / 0.5 = 200 units.
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeSectorOccluded {
    width: 400
    height: 400
    angleAt: 0
    angleSpan: 90
    radius: 100
    positionScale: 0.5
    sourceX: 100
    sourceY: 100
    occluders: [{ x: 100, y: 50, r: 10 }, { x: 120, y: 60, r: 5 }]
}
)");
    ASSERT_NE(item, nullptr);

    // Relative to the apex the first pillar is 50 units dead ahead (near face
    // 40) and the second 20 east by 40 north (near face hypot(20,40) - 5);
    // radii come back in px, so each halves.
    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_GE(polyline.size(), 3);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, 0)), 20, 1e-6);
    const auto beta = std::atan2(20.0, 40.0) * 180 / Pi;
    EXPECT_NEAR(radiusOf(vertexAt(polyline, beta)), (std::hypot(20.0, 40.0) - 5) * 0.5, 1e-6);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, -40)), 100, 1e-6);
}

TEST(ShapeSectorOccluded, WedgeWrappingPastNorthStillInsertsExactRays)
{
    auto engine = QQmlEngine{};
    // Boresight 340 with a 90-degree span opens at 295 and closes at 25, so a
    // pillar at bearing 11 sits inside only once its critical bearings wrap.
    // 11 is off the uniform grid, so a dropped centre ray shows in the radius.
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeSectorOccluded {
    width: 400
    height: 400
    angleAt: 340
    angleSpan: 90
    radius: 100
    positionScale: 1
    occluders: [{ x: 9.540449, y: -49.081357, r: 10 }]
}
)");
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_GE(polyline.size(), 3);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, 11)), 40, 1e-5);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, -50)), 100, 1e-6);
}

TEST(ShapeSectorOccluded, RimAgreesWithTheLineOfSightRule)
{
    auto engine = QQmlEngine{};
    // A mixed picture: overlapping shadows about the boresight, a wedge-edge
    // straddler, a disc whose centre sits past reach, and one behind.
    const auto discs = std::vector<Disc>{
        {0, -50, 10}, {-8, -80, 20}, {45, -45, 15}, {30, -101, 8}, {0, 60, 20},
    };
    const auto item = loadWedge(engine,
                                "[{ x: 0, y: -50, r: 10 }, { x: -8, y: -80, r: 20 }, "
                                "{ x: 45, y: -45, r: 15 }, { x: 30, y: -101, r: 8 }, { x: 0, y: 60, r: 20 }]");
    ASSERT_NE(item, nullptr);

    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_GE(polyline.size(), 3);
    for (auto i = 1; i < polyline.size() - 1; ++i)
    {
        const auto rim = radiusOf(polyline[i]);
        const auto bearing = bearingOf(polyline[i]);
        const auto ux = std::sin(bearing * Pi / 180);
        const auto uy = -std::cos(bearing * Pi / 180);
        // Tangent rays sit on the rule's boundary, where rounding can land
        // either side; the margins below only hold away from that cliff.
        auto tangent = false;
        for (const auto& disc : discs)
        {
            const auto d = std::hypot(disc.x, disc.y);
            const auto beta = std::atan2(disc.x, -disc.y) * 180 / Pi;
            const auto alpha = std::asin(std::min(1.0, disc.r / d)) * 180 / Pi;
            tangent = tangent || std::abs(angularDistance(bearing, beta) - alpha) < 0.06;
        }
        if (tangent)
        {
            continue;
        }
        // Shy of the rim the line is clear; past a shadowed rim it is not.
        EXPECT_FALSE(blocked(ux, uy, rim * 0.98, discs)) << "bearing " << bearing;
        if (rim < 99)
        {
            EXPECT_TRUE(blocked(ux, uy, rim * 1.05, discs)) << "bearing " << bearing;
        }
    }
}

TEST(ShapeSectorOccluded, ApexInsideAPillarSeesNothing)
{
    auto engine = QQmlEngine{};
    const auto item = loadWedge(engine, "[{ x: 3, y: -3, r: 8 }]");
    ASSERT_NE(item, nullptr);

    EXPECT_TRUE(item->property("polyline").value<QList<QPointF>>().isEmpty());
}

TEST(ShapeSectorOccluded, FullCircleClosesRimToRim)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeSectorOccluded {
    width: 400
    height: 400
    angleSpan: 360
    radius: 100
    positionScale: 1
    occluders: [{ x: 0, y: 50, r: 10 }]
}
)");
    ASSERT_NE(item, nullptr);

    // No apex vertex on an all-round sweep: the loop closes rim to rim, and
    // the southern pillar still bites to its near face.
    const auto polyline = item->property("polyline").value<QList<QPointF>>();
    ASSERT_GE(polyline.size(), 3);
    EXPECT_EQ(polyline.first(), polyline.last());
    EXPECT_GT(radiusOf(polyline.first()), 1);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, 180)), 40, 1e-6);
    EXPECT_NEAR(radiusOf(vertexAt(polyline, 0)), 100, 1e-6);
}

TEST(ShapeSectorOccluded, EmptyWithoutReach)
{
    auto engine = QQmlEngine{};
    const auto item = load(engine, R"(
import QtQuick
import awen.shapes
ShapeSectorOccluded {
    width: 400
    height: 400
    angleSpan: 90
    radius: 100
    positionScale: 0
}
)");
    ASSERT_NE(item, nullptr);

    EXPECT_TRUE(item->property("polyline").value<QList<QPointF>>().isEmpty());
}
