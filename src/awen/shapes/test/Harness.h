#pragma once

#include <memory>

#include <QQmlComponent>
#include <QQmlEngine>
#include <QUrl>

#include <gtest/gtest.h>

/// @brief Instantiates an inline QML harness; the awen.shapes import resolves
/// via QML_IMPORT_PATH, set once in main(). Fails the running test on
/// component errors.
inline auto load(QQmlEngine& engine, const char* qml) -> std::unique_ptr<QObject>
{
    auto component = QQmlComponent{&engine};
    component.setData(qml, QUrl{QStringLiteral("qrc:/awen-shapes-test/harness.qml")});

    auto object = std::unique_ptr<QObject>{component.create()};
    if (object == nullptr)
    {
        ADD_FAILURE() << component.errorString().toStdString();
    }
    return object;
}
