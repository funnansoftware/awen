#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

auto main(int argc, char** argv) -> int
{
    QGuiApplication app{argc, argv};

    // A real Qt Quick call so the linker keeps the Qt6Quick import; without any
    // Quick symbol reference the DLL is dropped and the deployed app fails to start.
    QQuickWindow::setDefaultAlphaBuffer(QQuickWindow::hasDefaultAlphaBuffer());

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule("Briarthorn", "Main");

    // Test seam for the tst_apploads ctest: quit after the given delay, so a clean
    // exit asserts Main.qml fully loaded.
    if (qEnvironmentVariableIsSet("BRIARTHORN_SMOKE_QUIT_MS"))
    {
        QTimer::singleShot(qEnvironmentVariableIntValue("BRIARTHORN_SMOKE_QUIT_MS"), &app, [] { QCoreApplication::quit(); });
    }

    return QGuiApplication::exec();
}
