#include "App.h"

#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

auto awen::runApp(int argc, char** argv, const char* uri) -> int
{
    QGuiApplication app{argc, argv};

    // A real Qt Quick call so the linker keeps the Qt6Quick import; without any
    // Quick symbol reference the DLL is dropped and the deployed app fails to start.
    QQuickWindow::setDefaultAlphaBuffer(QQuickWindow::hasDefaultAlphaBuffer());

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule(uri, "Main");

    // Test seam for the tst_<app>_loads ctest awen_add_executable registers: quit
    // after the given delay, so a clean exit asserts Main.qml fully loaded.
    if (qEnvironmentVariableIsSet("AWEN_SMOKE_QUIT_MS"))
    {
        QTimer::singleShot(qEnvironmentVariableIntValue("AWEN_SMOKE_QUIT_MS"), &app, [] { QCoreApplication::quit(); });
    }

    return QGuiApplication::exec();
}
