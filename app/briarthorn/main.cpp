#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>

auto main(int argc, char** argv) -> int
{
    QGuiApplication app{argc, argv};

    // A real Qt Quick call so the linker keeps the Qt6Quick import. The deploy
    // step sees Qt6::Quick in the link closure and ships no qtquick2plugin
    // loader, so the QtQuick import in Main.qml can only resolve against the
    // types the loaded library registers in-process — an exe without any Quick
    // symbol reference drops the DLL and fails to start. See app/awen/main.cpp.
    QQuickWindow::setDefaultAlphaBuffer(QQuickWindow::hasDefaultAlphaBuffer());

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.loadFromModule("Briarthorn", "Main");

    // Test seam: with BRIARTHORN_SMOKE_QUIT_MS set, quit that many milliseconds
    // after start. Combined with the objectCreationFailed exit above, a clean exit
    // asserts Main.qml — including its `import awen.gamepad` — fully loaded, with no
    // window to close by hand. The tst_apploads ctest drives this headless.
    if (qEnvironmentVariableIsSet("BRIARTHORN_SMOKE_QUIT_MS"))
    {
        QTimer::singleShot(qEnvironmentVariableIntValue("BRIARTHORN_SMOKE_QUIT_MS"), &app, [] { QCoreApplication::quit(); });
    }

    return QGuiApplication::exec();
}
