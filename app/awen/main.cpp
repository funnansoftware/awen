#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>
#include <QUrl>

auto main(int argc, char** argv) -> int
{
    QGuiApplication app{argc, argv};

    // A real Qt Quick call so the linker keeps the Qt6Quick import; without any
    // Quick symbol reference the DLL is dropped and the deployed app fails to start.
    QQuickWindow::setDefaultAlphaBuffer(QQuickWindow::hasDefaultAlphaBuffer());

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);

#ifdef AWENAPP_QML_SOURCE_DIR
    // Load the QML straight from the source tree so qmlpreview can live-reload
    // it: qmlpreview pushes edited files over the QML debug connection, and the
    // engine only reloads QML it loaded from a file URL. The define is
    // desktop-debug only (see CMakeLists.txt), which is exactly where the source
    // tree is present and the debug connection exists.
    engine.load(QUrl::fromLocalFile(QStringLiteral(AWENAPP_QML_SOURCE_DIR "/Main.qml")));
#else
    // Everywhere else, load the compiled AwenApp module baked into the binary,
    // so the shipped app carries its own QML and needs no source tree.
    engine.loadFromModule("AwenApp", "Main");
#endif

    // Test seam for the tst_awen_loads ctest awen_add_executable registers: quit
    // after the given delay, so a clean exit asserts Main.qml fully loaded.
    if (qEnvironmentVariableIsSet("AWEN_SMOKE_QUIT_MS"))
    {
        QTimer::singleShot(qEnvironmentVariableIntValue("AWEN_SMOKE_QUIT_MS"), &app, [] { QCoreApplication::quit(); });
    }

    return QGuiApplication::exec();
}
