#include <memory>

#include <QQmlComponent>
#include <QQmlEngine>
#include <QUrl>

#include <gtest/gtest.h>

using std::unique_ptr;

namespace
{
    /// @brief Instantiates an inline QML harness; the awen.command import
    /// resolves via QML_IMPORT_PATH, set once in main(). Fails the running
    /// test on component errors.
    auto load(QQmlEngine& engine, const char* qml) -> unique_ptr<QObject>
    {
        auto component = QQmlComponent{&engine};
        component.setData(qml, QUrl{QStringLiteral("qrc:/awen-command-test/harness.qml")});

        auto object = unique_ptr<QObject>{component.create()};
        if (object == nullptr)
        {
            ADD_FAILURE() << component.errorString().toStdString();
        }
        return object;
    }

    /// @brief The named emitter object declared on the harness root.
    auto emitter(QObject& queue, const char* name) -> QObject*
    {
        const auto object = queue.property(name).value<QObject*>();
        EXPECT_NE(object, nullptr);
        return object;
    }

    /// @brief Calls post() on an emitter, with optional per-post overrides.
    auto post(QObject& command, const QVariant& overrides = QVariant{}) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&command, "post", Q_ARG(QVariant, overrides)));
    }

    auto tick(QObject& queue) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&queue, "tick"));
    }

    // Two emitters over one queue: a coalescing continuous verb with a real
    // payload and a discrete verb whose target arrives per post.
    constexpr auto Harness = R"(
import QtQml
import awen.command

CommandQueue {
    id: root

    property Command steer: Command {
        queue: root
        name: "steer"
        coalesce: true

        property real value: 0

        function payload(): var {
            return { value: root.steer.value };
        }
    }

    property Command fire: Command {
        queue: root
        name: "fire"

        property string target: ""

        function payload(): var {
            return { target: root.fire.target };
        }
    }

    function tick() {
        root.update(0.016);
    }
    function names(): string {
        return root.commands.map(record => record.name).join(",");
    }
    function pendingCount(): int {
        return root.pending.length;
    }
    function steerValue(index: int): real {
        return root.commands[index].payload.value;
    }
    function fireTarget(index: int): string {
        return root.commands[index].payload.target;
    }
}
)";
}

TEST(Command, PostSnapshotsDeclaredPayload)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    const auto steer = emitter(*queue, "steer");
    steer->setProperty("value", 0.7);
    post(*steer);
    tick(*queue);

    auto joined = QString{};
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "names", Q_RETURN_ARG(QString, joined)));
    EXPECT_EQ(joined, QStringLiteral("steer"));

    auto value = 0.0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "steerValue", Q_RETURN_ARG(double, value), Q_ARG(int, 0)));
    EXPECT_DOUBLE_EQ(value, 0.7);
}

TEST(Command, OverridesPatchTheSnapshot)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    const auto fire = emitter(*queue, "fire");
    post(*fire, QVariantMap{{QStringLiteral("target"), QStringLiteral("bandit")}});
    tick(*queue);

    auto target = QString{};
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "fireTarget", Q_RETURN_ARG(QString, target), Q_ARG(int, 0)));
    EXPECT_EQ(target, QStringLiteral("bandit"));

    // The override patched the record, not the standing declaration.
    EXPECT_EQ(fire->property("target").toString(), QString{});
}

TEST(Command, CoalesceKeepsOneRecordInItsSlot)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    const auto steer = emitter(*queue, "steer");
    const auto fire = emitter(*queue, "fire");

    steer->setProperty("value", 0.2);
    post(*steer);
    post(*fire);
    steer->setProperty("value", 0.9);
    post(*steer);

    auto pending = 0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "pendingCount", Q_RETURN_ARG(int, pending)));
    EXPECT_EQ(pending, 2);

    tick(*queue);
    auto joined = QString{};
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "names", Q_RETURN_ARG(QString, joined)));
    EXPECT_EQ(joined, QStringLiteral("steer,fire"));

    auto value = 0.0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "steerValue", Q_RETURN_ARG(double, value), Q_ARG(int, 0)));
    EXPECT_DOUBLE_EQ(value, 0.9);
}

TEST(Command, DisabledPostsNothing)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    const auto steer = emitter(*queue, "steer");
    steer->setProperty("enabled", false);
    post(*steer);

    auto pending = -1;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "pendingCount", Q_RETURN_ARG(int, pending)));
    EXPECT_EQ(pending, 0);
}

TEST(Command, SnapshotIgnoresLaterPropertyChanges)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    const auto steer = emitter(*queue, "steer");
    steer->setProperty("value", 0.3);
    post(*steer);
    steer->setProperty("value", 0.8);
    tick(*queue);

    auto value = 0.0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "steerValue", Q_RETURN_ARG(double, value), Q_ARG(int, 0)));
    EXPECT_DOUBLE_EQ(value, 0.3);
}
