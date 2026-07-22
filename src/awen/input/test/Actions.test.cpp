#include <memory>

#include <QQmlComponent>
#include <QQmlEngine>
#include <QUrl>

#include <gtest/gtest.h>

using std::unique_ptr;

namespace
{
    /// @brief Instantiates an inline QML harness; the awen.input import
    /// resolves via QML_IMPORT_PATH, set once in main(). Fails the running
    /// test on component errors.
    auto load(QQmlEngine& engine, const char* qml) -> unique_ptr<QObject>
    {
        auto component = QQmlComponent{&engine};
        component.setData(qml, QUrl{QStringLiteral("qrc:/awen-input-test/harness.qml")});

        auto object = unique_ptr<QObject>{component.create()};
        if (object == nullptr)
        {
            ADD_FAILURE() << component.errorString().toStdString();
        }
        return object;
    }

    /// @brief Forwards one digital event (key or button) to the map, returning
    /// whether an action consumed it.
    auto route(QObject& map, const char* channel, int code) -> bool
    {
        auto consumed = false;
        EXPECT_TRUE(QMetaObject::invokeMethod(&map, channel, Q_RETURN_ARG(bool, consumed), Q_ARG(int, code)));
        return consumed;
    }

    /// @brief Forwards one axis move to the map, returning whether an action
    /// consumed it.
    auto move(QObject& map, int axis, double position) -> bool
    {
        auto consumed = false;
        EXPECT_TRUE(QMetaObject::invokeMethod(&map, "axisMoved", Q_RETURN_ARG(bool, consumed), Q_ARG(int, axis), Q_ARG(double, position)));
        return consumed;
    }

    auto steer(const QObject& map) -> double
    {
        return map.property("steerValue").toDouble();
    }

    auto throttle(const QObject& map) -> double
    {
        return map.property("throttleValue").toDouble();
    }

    // Briarthorn's real shape in miniature: a signed steer and a 0..1 throttle,
    // each driven by keys, buttons and an axis at once. Button and axis codes
    // are plain ints — the module never depends on awen.gamepad.
    constexpr auto Harness = R"(
import QtQml
import awen.input

Actions {
    id: root

    property Axis steer: Axis {}
    property Axis throttle: Axis {
        minimum: 0
    }

    readonly property real steerValue: root.steer.value
    readonly property real throttleValue: root.throttle.value

    ActionKey {
        control: root.steer
        positive: [Qt.Key_D]
        negative: [Qt.Key_A]
    }
    ActionKey {
        control: root.throttle
        positive: [Qt.Key_W]
    }
    ActionButton {
        control: root.steer
        positive: [14]
        negative: [13]
    }
    ActionAxis {
        control: root.steer
        axis: 0
    }
    ActionAxis {
        control: root.throttle
        axis: 1
        scale: -1
    }
}
)";
}

TEST(Actions, KeyPairFoldsHeldKeysIntoSteer)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(route(*map, "keyPressed", Qt::Key_D));
    EXPECT_DOUBLE_EQ(steer(*map), 1.0);

    EXPECT_TRUE(route(*map, "keyPressed", Qt::Key_A));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);

    EXPECT_TRUE(route(*map, "keyReleased", Qt::Key_D));
    EXPECT_DOUBLE_EQ(steer(*map), -1.0);

    EXPECT_TRUE(route(*map, "keyReleased", Qt::Key_A));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);
}

TEST(Actions, LeavesUnmappedInputsUnconsumed)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_FALSE(route(*map, "keyPressed", Qt::Key_X));
    EXPECT_FALSE(route(*map, "buttonPressed", 2));
    EXPECT_FALSE(move(*map, 5, 0.9));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);
    EXPECT_DOUBLE_EQ(throttle(*map), 0.0);
}

TEST(Actions, ButtonPairFoldsLikeKeys)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(route(*map, "buttonPressed", 14));
    EXPECT_DOUBLE_EQ(steer(*map), 1.0);

    EXPECT_TRUE(route(*map, "buttonPressed", 13));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);

    EXPECT_TRUE(route(*map, "buttonReleased", 14));
    EXPECT_DOUBLE_EQ(steer(*map), -1.0);

    EXPECT_TRUE(route(*map, "buttonReleased", 13));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);
}

TEST(Actions, AxisDeadzoneFoldsRestToZero)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(move(*map, 0, 0.6));
    EXPECT_DOUBLE_EQ(steer(*map), 0.6);

    // Within the default 0.15 deadzone: consumed, but folded to rest.
    EXPECT_TRUE(move(*map, 0, 0.1));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);
}

TEST(Actions, AxisScaleInvertsThrottleStick)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(move(*map, 1, -0.8));
    EXPECT_DOUBLE_EQ(throttle(*map), 0.8);

    // Stick pushed the other way drives below the throttle's floor.
    EXPECT_TRUE(move(*map, 1, 0.5));
    EXPECT_DOUBLE_EQ(throttle(*map), 0.0);
}

TEST(Actions, SourcesFoldIntoOneAxis)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(route(*map, "keyPressed", Qt::Key_D));
    EXPECT_TRUE(move(*map, 0, -0.5));
    EXPECT_DOUBLE_EQ(steer(*map), 0.5);

    // A third source saturates the fold at the axis's maximum.
    EXPECT_TRUE(route(*map, "buttonPressed", 14));
    EXPECT_DOUBLE_EQ(steer(*map), 1.0);

    EXPECT_TRUE(route(*map, "buttonReleased", 14));
    EXPECT_TRUE(route(*map, "keyReleased", Qt::Key_D));
    EXPECT_DOUBLE_EQ(steer(*map), -0.5);

    EXPECT_TRUE(move(*map, 0, 0.0));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);
}

TEST(Actions, ThrottleClampsAtItsFloor)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(route(*map, "keyPressed", Qt::Key_W));
    EXPECT_DOUBLE_EQ(throttle(*map), 1.0);

    EXPECT_TRUE(move(*map, 1, 1.0));
    EXPECT_DOUBLE_EQ(throttle(*map), 0.0);

    EXPECT_TRUE(route(*map, "keyReleased", Qt::Key_W));
    EXPECT_DOUBLE_EQ(throttle(*map), 0.0);

    EXPECT_TRUE(move(*map, 1, 0.0));
    EXPECT_DOUBLE_EQ(throttle(*map), 0.0);
}

TEST(Actions, ResetDropsAllHeldState)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, Harness);
    ASSERT_NE(map, nullptr);

    EXPECT_TRUE(route(*map, "keyPressed", Qt::Key_D));
    EXPECT_TRUE(move(*map, 0, 0.5));
    EXPECT_DOUBLE_EQ(steer(*map), 1.0);

    EXPECT_TRUE(QMetaObject::invokeMethod(map.get(), "reset"));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);

    // The release that never arrived is a no-op now, not an inversion.
    EXPECT_TRUE(route(*map, "keyReleased", Qt::Key_D));
    EXPECT_DOUBLE_EQ(steer(*map), 0.0);
}

TEST(Actions, SharedInputReachesEveryBinding)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, R"(
import QtQml
import awen.input

Actions {
    id: root

    property Axis steer: Axis {}
    property Axis throttle: Axis {
        minimum: 0
    }

    readonly property real steerValue: root.steer.value
    readonly property real throttleValue: root.throttle.value

    ActionKey {
        control: root.steer
        positive: [Qt.Key_S]
    }
    ActionKey {
        control: root.throttle
        positive: [Qt.Key_S]
    }
}
)");
    ASSERT_NE(map, nullptr);

    // One key bound twice drives both axes; fan() must not short-circuit.
    EXPECT_TRUE(route(*map, "keyPressed", Qt::Key_S));
    EXPECT_DOUBLE_EQ(steer(*map), 1.0);
    EXPECT_DOUBLE_EQ(throttle(*map), 1.0);
}

TEST(Actions, EmptyMapConsumesNothing)
{
    auto engine = QQmlEngine{};
    const auto map = load(engine, R"(
import awen.input
Actions {}
)");
    ASSERT_NE(map, nullptr);

    EXPECT_FALSE(route(*map, "keyPressed", Qt::Key_W));
    EXPECT_FALSE(move(*map, 0, 1.0));
}
