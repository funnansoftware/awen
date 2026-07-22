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

    /// @brief Posts one plain record through the harness helper.
    auto post(QObject& queue, const char* name, double value) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&queue, "postPlain", Q_ARG(QString, QString::fromLatin1(name)), Q_ARG(double, value)));
    }

    /// @brief Runs the queue's tick, publishing the pending batch.
    auto tick(QObject& queue) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&queue, "tick"));
    }

    /// @brief The published batch's record names, comma-joined.
    auto names(QObject& queue) -> QString
    {
        auto joined = QString{};
        EXPECT_TRUE(QMetaObject::invokeMethod(&queue, "names", Q_RETURN_ARG(QString, joined)));
        return joined;
    }

    auto batchValue(QObject& queue, int index) -> double
    {
        auto value = 0.0;
        EXPECT_TRUE(QMetaObject::invokeMethod(&queue, "value", Q_RETURN_ARG(double, value), Q_ARG(int, index)));
        return value;
    }

    // The harness exposes typed helpers because the record buffers are plain
    // JS arrays, awkward to walk from C++ directly.
    constexpr auto Harness = R"(
import QtQml
import awen.command

CommandQueue {
    id: root

    property QtObject keyA: QtObject {}

    function postPlain(name: string, value: real) {
        root.post(name, { value: value });
    }
    function postKeyed(value: real) {
        root.post("keyed", { value: value }, root.keyA);
    }
    function tick() {
        root.update(0.016);
    }
    function names(): string {
        return root.commands.map(record => record.name).join(",");
    }
    function value(index: int): real {
        return root.commands[index].payload.value;
    }
    function tamper(index: int): real {
        root.commands[index].payload.value = 99;
        return root.commands[index].payload.value;
    }
    function pendingCount(): int {
        return root.pending.length;
    }
    function batchCount(): int {
        return root.commands.length;
    }
    function warnedCount(): int {
        return root.warned.size;
    }
}
)";
}

TEST(CommandQueue, PublishesRecordsInPostOrder)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "a", 1);
    post(*queue, "b", 2);
    post(*queue, "c", 3);
    tick(*queue);
    EXPECT_EQ(names(*queue), QStringLiteral("a,b,c"));
}

TEST(CommandQueue, CoalesceReplacesPayloadInPlace)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "x", 1);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "postKeyed", Q_ARG(double, 1.0)));
    post(*queue, "y", 2);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "postKeyed", Q_ARG(double, 9.0)));

    auto pending = 0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "pendingCount", Q_RETURN_ARG(int, pending)));
    EXPECT_EQ(pending, 3);

    tick(*queue);
    EXPECT_EQ(names(*queue), QStringLiteral("x,keyed,y"));
    EXPECT_DOUBLE_EQ(batchValue(*queue, 1), 9.0);
}

TEST(CommandQueue, PublishSwapsBatches)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "a", 1);
    tick(*queue);

    auto batch = 0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "batchCount", Q_RETURN_ARG(int, batch)));
    EXPECT_EQ(batch, 1);

    tick(*queue);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "batchCount", Q_RETURN_ARG(int, batch)));
    EXPECT_EQ(batch, 0);
}

TEST(CommandQueue, CountsUnconsumedWhenBatchAges)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "ghost", 0);
    tick(*queue);
    EXPECT_EQ(queue->property("unconsumed").toInt(), 0);

    // Nothing consumed the batch before the next publish.
    tick(*queue);
    EXPECT_EQ(queue->property("unconsumed").toInt(), 1);
}

TEST(CommandQueue, ClearDropsPendingAndPublished)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "a", 1);
    tick(*queue);
    post(*queue, "b", 2);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "clear"));

    auto count = -1;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "batchCount", Q_RETURN_ARG(int, count)));
    EXPECT_EQ(count, 0);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "pendingCount", Q_RETURN_ARG(int, count)));
    EXPECT_EQ(count, 0);

    tick(*queue);
    EXPECT_EQ(queue->property("unconsumed").toInt(), 0);
}

TEST(CommandQueue, CoalesceStopsAtThePublishBoundary)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "postKeyed", Q_ARG(double, 1.0)));
    tick(*queue);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "postKeyed", Q_ARG(double, 2.0)));

    // The published record keeps its payload; the re-post opens a new one.
    EXPECT_DOUBLE_EQ(batchValue(*queue, 0), 1.0);

    auto pending = 0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "pendingCount", Q_RETURN_ARG(int, pending)));
    EXPECT_EQ(pending, 1);
}

TEST(CommandQueue, RecordsOneWarningPerUnconsumedName)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    // The same name aging out repeatedly warns once; a new name warns again.
    post(*queue, "ghost", 0);
    tick(*queue);
    post(*queue, "ghost", 0);
    tick(*queue);
    tick(*queue);

    auto warned = 0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "warnedCount", Q_RETURN_ARG(int, warned)));
    EXPECT_EQ(warned, 1);

    post(*queue, "phantom", 0);
    tick(*queue);
    tick(*queue);
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "warnedCount", Q_RETURN_ARG(int, warned)));
    EXPECT_EQ(warned, 2);
}

TEST(CommandQueue, FreezesPayloads)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "a", 1);
    tick(*queue);

    auto value = 0.0;
    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "tamper", Q_RETURN_ARG(double, value), Q_ARG(int, 0)));
    EXPECT_DOUBLE_EQ(value, 1.0);
}
