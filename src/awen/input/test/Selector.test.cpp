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

    /// @brief Moves the cursor; move() takes an int, so a plain invoke with a
    /// double argument would never match.
    auto move(QObject& selector, int delta) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&selector, "move", Q_ARG(int, delta)));
    }

    auto call(QObject& selector, const char* function) -> void
    {
        EXPECT_TRUE(QMetaObject::invokeMethod(&selector, function));
    }

    // The fired counter records each activation; lastFired which item it chose.
    constexpr auto Harness = R"(
import QtQml
import awen.input

Selector {
    id: root

    property int fired
    property int lastFired: -1
    onActivated: index => {
        root.fired += 1;
        root.lastFired = index;
    }

    count: 3
}
)";
}

TEST(Selector, DefaultsToTopDisengaged)
{
    auto engine = QQmlEngine{};
    const auto selector = load(engine, Harness);
    ASSERT_NE(selector, nullptr);

    EXPECT_EQ(selector->property("index").toInt(), 0);
    EXPECT_FALSE(selector->property("engaged").toBool());
}

TEST(Selector, MoveClampsAtTheEndsAndEngages)
{
    auto engine = QQmlEngine{};
    const auto selector = load(engine, Harness);
    ASSERT_NE(selector, nullptr);

    move(*selector, -1);
    EXPECT_EQ(selector->property("index").toInt(), 0);
    EXPECT_TRUE(selector->property("engaged").toBool());

    move(*selector, 1);
    move(*selector, 1);
    move(*selector, 1);
    EXPECT_EQ(selector->property("index").toInt(), 2);
}

TEST(Selector, ActivateFiresPrimaryUntilNavigated)
{
    auto engine = QQmlEngine{};
    const auto selector = load(engine, Harness);
    ASSERT_NE(selector, nullptr);

    selector->setProperty("primary", 1);
    call(*selector, "activate");
    EXPECT_EQ(selector->property("fired").toInt(), 1);
    EXPECT_EQ(selector->property("lastFired").toInt(), 1);

    // Navigation replaces the primary with the actual selection.
    move(*selector, 1);
    move(*selector, 1);
    call(*selector, "activate");
    EXPECT_EQ(selector->property("fired").toInt(), 2);
    EXPECT_EQ(selector->property("lastFired").toInt(), 2);
}

TEST(Selector, EmptyMenuNeitherMovesNorFires)
{
    auto engine = QQmlEngine{};
    const auto selector = load(engine, Harness);
    ASSERT_NE(selector, nullptr);

    selector->setProperty("count", 0);
    move(*selector, 1);
    EXPECT_EQ(selector->property("index").toInt(), 0);
    EXPECT_FALSE(selector->property("engaged").toBool());

    call(*selector, "activate");
    EXPECT_EQ(selector->property("fired").toInt(), 0);
}

TEST(Selector, ShrinkingCountClampsTheIndex)
{
    auto engine = QQmlEngine{};
    const auto selector = load(engine, Harness);
    ASSERT_NE(selector, nullptr);

    move(*selector, 2);
    EXPECT_EQ(selector->property("index").toInt(), 2);

    selector->setProperty("count", 2);
    EXPECT_EQ(selector->property("index").toInt(), 1);
}

TEST(Selector, ResetReturnsToTopDisengaged)
{
    auto engine = QQmlEngine{};
    const auto selector = load(engine, Harness);
    ASSERT_NE(selector, nullptr);

    move(*selector, 2);
    call(*selector, "reset");
    EXPECT_EQ(selector->property("index").toInt(), 0);
    EXPECT_FALSE(selector->property("engaged").toBool());

    // Disengaged again, so activate() falls back to the primary.
    call(*selector, "activate");
    EXPECT_EQ(selector->property("lastFired").toInt(), 0);
}
