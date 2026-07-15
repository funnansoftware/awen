#include <quick/Application.hpp>

#include <cstdlib>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QTimer>
#include <QVariant>

#include <Briarthorn.hpp>
#include <quick/GameController.hpp>

auto bt::quick::run(Briarthorn& briarthorn, int argc, char** argv) -> int
{
    QGuiApplication app{argc, argv};

    GameController controller{briarthorn};

    QQmlApplicationEngine engine;
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed, &app, [] { QCoreApplication::exit(EXIT_FAILURE); }, Qt::QueuedConnection);
    engine.setInitialProperties({{"game", QVariant::fromValue(&controller)}});
    engine.loadFromModule("briarthorn.quick", "Main");

    auto* window = engine.rootObjects().isEmpty() ? nullptr : qobject_cast<QQuickWindow*>(engine.rootObjects().first());
    if (window == nullptr)
    {
        return EXIT_FAILURE;
    }

    // The frame loop: after each presented frame, step the simulation once and
    // (via stepped -> WorldView::update) schedule the next frame — vsync-locked,
    // like the raylib loop. frameSwapped is emitted on the render thread, so the
    // queued connection runs frame() on the GUI thread.
    QObject::connect(window, &QQuickWindow::frameSwapped, &controller, &GameController::frame, Qt::QueuedConnection);

    // Test seam: with BRIARTHORN_SMOKE_QUIT_MS set, quit that many milliseconds
    // after startup. Combined with the failure exit above, a clean exit asserts
    // Main.qml fully loaded and the frame loop ran — no user needed to close the
    // window. BRIARTHORN_SMOKE_GRAB additionally saves the last rendered frame
    // to the given image path first, so rendering itself is assertable headless.
    if (qEnvironmentVariableIsSet("BRIARTHORN_SMOKE_QUIT_MS"))
    {
        QTimer::singleShot(qEnvironmentVariableIntValue("BRIARTHORN_SMOKE_QUIT_MS"), window, [window] {
            if (const auto grab = qEnvironmentVariable("BRIARTHORN_SMOKE_GRAB"); !grab.isEmpty())
            {
                window->grabWindow().save(grab);
            }
            QCoreApplication::quit();
        });
    }

    // The window is up: start real-time stepping now so start-up cost isn't
    // folded into the first frame as a catch-up burst.
    briarthorn.resetClock();

    return QGuiApplication::exec();
}
