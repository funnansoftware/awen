#include <memory>

#include <QQmlComponent>
#include <QQmlEngine>
#include <QUrl>

#include <gtest/gtest.h>

using std::unique_ptr;

namespace
{
    /// @brief Instantiates an inline QML harness; the awen.entity import
    /// resolves via QML_IMPORT_PATH, set once in main(). Fails the running
    /// test on component errors.
    auto load(QQmlEngine& engine, const char* qml) -> unique_ptr<QObject>
    {
        auto component = QQmlComponent{&engine};
        component.setData(qml, QUrl{QStringLiteral("qrc:/awen-entity-test/harness.qml")});

        auto object = unique_ptr<QObject>{component.create()};
        if (object == nullptr)
        {
            ADD_FAILURE() << component.errorString().toStdString();
        }
        return object;
    }

    /// @brief Calls the runner's tick(dt), as the frame clock would.
    auto tick(QObject& runner, double dt) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&runner, "tick", Q_ARG(double, dt)));
    }

    // Derived systems record into the root through a property: an inline
    // component does not share scope with its declaring file, so it cannot
    // reach the root by id. The plain System in the middle proves the base
    // update() is a callable no-op.
    constexpr auto OrderedHarness = R"(
import QtQml
import awen.entity

Systems {
    id: root
    running: false

    property string calls
    property real lastDt

    component Recorder: System {
        required property var log
        required property string tag
        function update(dt: real) {
            log.calls += tag;
            log.lastDt = dt;
        }
    }

    Recorder { log: root; tag: "a" }
    System {}
    Recorder { log: root; tag: "b" }
    Recorder { log: root; tag: "c" }
}
)";

    constexpr auto DisabledHarness = R"(
import QtQml
import awen.entity

Systems {
    id: root
    running: false

    property string calls

    component Recorder: System {
        required property var log
        required property string tag
        function update(dt: real) {
            log.calls += tag;
        }
    }

    Recorder { log: root; tag: "a" }
    Recorder { log: root; tag: "b"; enabled: false }
    Recorder { log: root; tag: "c" }
}
)";
}

TEST(Systems, RunsDerivedUpdatesInDeclarationOrder)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, OrderedHarness);
    ASSERT_NE(runner, nullptr);

    tick(*runner, 0.016);
    EXPECT_EQ(runner->property("calls").toString(), QStringLiteral("abc"));
}

TEST(Systems, ForwardsFrameSecondsToUpdate)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, OrderedHarness);
    ASSERT_NE(runner, nullptr);

    tick(*runner, 0.25);
    EXPECT_DOUBLE_EQ(runner->property("lastDt").toDouble(), 0.25);
}

TEST(Systems, SkipsDisabledSystems)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, DisabledHarness);
    ASSERT_NE(runner, nullptr);

    tick(*runner, 0.016);
    EXPECT_EQ(runner->property("calls").toString(), QStringLiteral("ac"));
}

TEST(Systems, DefaultsToRunning)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, R"(
import awen.entity
Systems {}
)");
    ASSERT_NE(runner, nullptr);

    EXPECT_TRUE(runner->property("running").toBool());
}
