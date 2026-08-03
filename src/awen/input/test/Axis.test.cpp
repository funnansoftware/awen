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

    /// @brief Calls one of the harness's real-parameter functions on the axis.
    auto call(QObject& axis, const char* function, double contribution) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&axis, function, Q_ARG(double, contribution)));
    }

    /// @brief Injects a discrete step; step() takes an int, so the double
    /// helper's argument would never match.
    auto step(QObject& axis, int direction) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&axis, "step", Q_ARG(int, direction)));
    }

    // Two distinct source objects prove contributions fold per source; the
    // change counter proves valueChanged fires once per actual move.
    constexpr auto Harness = R"(
import QtQml
import awen.input

Axis {
    id: root

    property int changes
    property int steps
    property int lastStep
    onValueChanged: root.changes += 1
    onStepped: direction => {
        root.steps += 1;
        root.lastStep = direction;
    }

    property QtObject sourceA: QtObject {}
    property QtObject sourceB: QtObject {}

    function pushA(contribution: real) {
        root.contribute(root.sourceA, contribution);
    }
    function pushB(contribution: real) {
        root.contribute(root.sourceB, contribution);
    }
}
)";
}

TEST(Axis, DefaultsToIdleUnitRange)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.0);
    EXPECT_DOUBLE_EQ(axis->property("minimum").toDouble(), -1.0);
    EXPECT_DOUBLE_EQ(axis->property("maximum").toDouble(), 1.0);
    EXPECT_TRUE(axis->property("enabled").toBool());
}

TEST(Axis, InvokeClampsToRange)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    call(*axis, "invoke", 2.5);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 1.0);

    call(*axis, "invoke", -3.0);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), -1.0);
}

TEST(Axis, SumsContributionsAcrossSources)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    call(*axis, "pushA", 1.0);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 1.0);

    call(*axis, "pushB", -1.0);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.0);

    call(*axis, "pushB", -0.25);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.75);
}

TEST(Axis, NotifiesOncePerRealChange)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    call(*axis, "pushA", 0.5);
    EXPECT_EQ(axis->property("changes").toInt(), 1);

    // The same contribution folds to the same value: no notification.
    call(*axis, "pushA", 0.5);
    EXPECT_EQ(axis->property("changes").toInt(), 1);

    // Two saturating invokes both fold to the maximum: one notification.
    call(*axis, "invoke", 3.0);
    call(*axis, "invoke", 2.0);
    EXPECT_EQ(axis->property("changes").toInt(), 2);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 1.0);
}

TEST(Axis, DisabledFreezesTheFoldUntilReEnabled)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    axis->setProperty("enabled", false);
    call(*axis, "pushA", 1.0);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.0);
    EXPECT_EQ(axis->property("changes").toInt(), 0);

    // Contributions kept recording, so re-enabling folds them in.
    axis->setProperty("enabled", true);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 1.0);
}

TEST(Axis, ReEnableRefoldsToLiveInputs)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    call(*axis, "pushA", 1.0);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 1.0);

    // The source releases during the disabled window; nothing may stick.
    axis->setProperty("enabled", false);
    call(*axis, "pushA", 0.0);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 1.0);

    axis->setProperty("enabled", true);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.0);
}

TEST(Axis, StepsOncePerEngagement)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    call(*axis, "pushA", 1.0);
    EXPECT_EQ(axis->property("steps").toInt(), 1);
    EXPECT_EQ(axis->property("lastStep").toInt(), 1);

    // Wobble on the engaged side stays one step; only rest re-arms it.
    call(*axis, "pushA", 0.6);
    call(*axis, "pushA", 1.0);
    EXPECT_EQ(axis->property("steps").toInt(), 1);

    // Rest is the whole band, not just zero: dipping inside it re-arms.
    call(*axis, "pushA", 0.4);
    call(*axis, "pushA", 1.0);
    EXPECT_EQ(axis->property("steps").toInt(), 2);

    call(*axis, "pushA", 0.0);
    EXPECT_EQ(axis->property("steps").toInt(), 2);

    call(*axis, "pushA", -1.0);
    EXPECT_EQ(axis->property("steps").toInt(), 3);
    EXPECT_EQ(axis->property("lastStep").toInt(), -1);
}

TEST(Axis, StepInjectsWithoutMovingTheFold)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    step(*axis, 1);
    EXPECT_EQ(axis->property("steps").toInt(), 1);
    EXPECT_EQ(axis->property("lastStep").toInt(), 1);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.0);

    // Injection ignores where the fold sits: a held direction must not block
    // steps arriving from another source.
    call(*axis, "pushA", 1.0);
    EXPECT_EQ(axis->property("steps").toInt(), 2);
    step(*axis, -1);
    EXPECT_EQ(axis->property("steps").toInt(), 3);
    EXPECT_EQ(axis->property("lastStep").toInt(), -1);
}

TEST(Axis, DisabledSwallowsStepsUntilReEnabled)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, Harness);
    ASSERT_NE(axis, nullptr);

    axis->setProperty("enabled", false);
    step(*axis, 1);
    call(*axis, "pushA", 1.0);
    EXPECT_EQ(axis->property("steps").toInt(), 0);

    // Re-enabling folds the recorded engagement in: that move is real, so it
    // steps once.
    axis->setProperty("enabled", true);
    EXPECT_EQ(axis->property("steps").toInt(), 1);
}

TEST(Axis, ClampsIntoCustomRange)
{
    auto engine = QQmlEngine{};
    const auto axis = load(engine, R"(
import awen.input
Axis {
    minimum: 0
    maximum: 1
}
)");
    ASSERT_NE(axis, nullptr);

    call(*axis, "invoke", -0.5);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.0);

    call(*axis, "invoke", 0.5);
    EXPECT_DOUBLE_EQ(axis->property("value").toDouble(), 0.5);
}
