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

    /// @brief One frame: the queue publishes, then every store consumes.
    auto frame(QObject& queue) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&queue, "frame"));
    }

    auto model(const QObject& queue) -> QObject*
    {
        return queue.property("model").value<QObject*>();
    }

    // A queue observed by two handler stores splitting the vocabulary, one
    // chaining handler that posts during its own consume, and a generic
    // recorder overriding consume() — briarthorn's shape in miniature.
    constexpr auto Harness = R"(
import QtQml
import awen.command

CommandQueue {
    id: root

    property QtObject model: QtObject {
        property real steer: 0
        property real throttle: 0
        property string log: ""
    }

    property Store game: Store {
        queue: root
        CommandHandler {
            name: "steer"
            onHandle: payload => root.model.steer = payload.value
        }
        CommandHandler {
            name: "off"
            enabled: false
            onHandle: payload => root.model.log += "off"
        }
        CommandHandler {
            name: "chain"
            onHandle: payload => root.post("steer", { value: 0.5 })
        }
    }

    property Store other: Store {
        queue: root
        CommandHandler {
            name: "throttle"
            onHandle: payload => root.model.throttle = payload.value
        }
    }

    property string replay: ""
    property Store recorder: Store {
        queue: root
        function consume(record: var) {
            root.replay += record.name + ";";
        }
    }

    function postPlain(name: string, value: real) {
        root.post(name, { value: value });
    }
    function frame() {
        root.update(0.016);
        root.game.update(0.016);
        root.other.update(0.016);
        root.recorder.update(0.016);
    }
}
)";
}

TEST(Store, RoutesRecordsByNameAcrossStores)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "steer", 0.9);
    post(*queue, "throttle", 0.4);
    frame(*queue);

    EXPECT_DOUBLE_EQ(model(*queue)->property("steer").toDouble(), 0.9);
    EXPECT_DOUBLE_EQ(model(*queue)->property("throttle").toDouble(), 0.4);

    // Both records found handlers, so the next publish reports none missed.
    frame(*queue);
    EXPECT_EQ(queue->property("unconsumed").toInt(), 0);
}

TEST(Store, DisabledHandlerLeavesRecordUnconsumed)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "off", 1);
    frame(*queue);
    frame(*queue);

    EXPECT_EQ(queue->property("unconsumed").toInt(), 1);
    EXPECT_EQ(model(*queue)->property("log").toString(), QString{});
}

TEST(Store, GenericConsumeObservesWithoutConsuming)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "steer", 0.9);
    post(*queue, "ghost", 1);
    frame(*queue);

    // The recorder saw every record, in batch order.
    EXPECT_EQ(queue->property("replay").toString(), QStringLiteral("steer;ghost;"));

    // Observation is not consumption: the unhandled record still ages out.
    frame(*queue);
    EXPECT_EQ(queue->property("unconsumed").toInt(), 1);
}

TEST(Store, HandlerPostsLandNextFrame)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, Harness);
    ASSERT_NE(queue, nullptr);

    post(*queue, "chain", 0);
    frame(*queue);
    EXPECT_DOUBLE_EQ(model(*queue)->property("steer").toDouble(), 0.0);

    frame(*queue);
    EXPECT_DOUBLE_EQ(model(*queue)->property("steer").toDouble(), 0.5);
}

TEST(Store, FirstDeclaredHandlerWins)
{
    auto engine = QQmlEngine{};
    const auto queue = load(engine, R"(
import QtQml
import awen.command

CommandQueue {
    id: root

    property string log: ""
    property Store dup: Store {
        queue: root
        CommandHandler {
            name: "x"
            onHandle: payload => root.log += "first"
        }
        CommandHandler {
            name: "x"
            onHandle: payload => root.log += "second"
        }
    }

    function go() {
        root.post("x", {});
        root.update(0.016);
        root.dup.update(0.016);
    }
}
)");
    ASSERT_NE(queue, nullptr);

    EXPECT_TRUE(QMetaObject::invokeMethod(queue.get(), "go"));
    EXPECT_EQ(queue->property("log").toString(), QStringLiteral("first"));
}
