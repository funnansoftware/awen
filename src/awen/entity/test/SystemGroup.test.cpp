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

    // A group slotted mid-run proves its children tick inside the group's
    // position in the outer declaration order, with dt forwarded through.
    constexpr auto NestedHarness = R"(
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
    SystemGroup {
        Recorder { log: root; tag: "b" }
        Recorder { log: root; tag: "c" }
    }
    Recorder { log: root; tag: "d" }
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

    SystemGroup {
        Recorder { log: root; tag: "a" }
        Recorder { log: root; tag: "b"; enabled: false }
        Recorder { log: root; tag: "c" }
    }
    SystemGroup {
        enabled: false
        Recorder { log: root; tag: "x" }
    }
}
)";
}

TEST(SystemGroup, TicksChildrenInsideTheOuterRunOrder)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, NestedHarness);
    ASSERT_NE(runner, nullptr);

    tick(*runner, 0.016);
    EXPECT_EQ(runner->property("calls").toString(), QStringLiteral("abcd"));
}

TEST(SystemGroup, ForwardsFrameSecondsToChildren)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, NestedHarness);
    ASSERT_NE(runner, nullptr);

    tick(*runner, 0.25);
    EXPECT_DOUBLE_EQ(runner->property("lastDt").toDouble(), 0.25);
}

TEST(SystemGroup, SkipsDisabledChildrenAndDisabledGroups)
{
    auto engine = QQmlEngine{};
    const auto runner = load(engine, DisabledHarness);
    ASSERT_NE(runner, nullptr);

    tick(*runner, 0.016);
    EXPECT_EQ(runner->property("calls").toString(), QStringLiteral("ac"));
}
