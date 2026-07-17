#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>

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

    return QGuiApplication::exec();
}
