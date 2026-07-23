#include "TouchScreen.h"

#include <QtGlobal>

#ifdef Q_OS_WASM
#include <emscripten.h>

// The browser's touch-point count, compiled in as a tiny JS probe — no eval, no
// embind. `| 0` coerces an undefined maxTouchPoints to 0.
EM_JS(int, awen_max_touch_points, (), { return navigator.maxTouchPoints | 0; });
#else
#include <algorithm>

#include <QInputDevice>
#endif

using awen::TouchScreen;

namespace
{
    auto detectTouchScreen() -> bool
    {
#ifdef Q_OS_WASM
        // Qt's wasm plugin exposes no persistent touch QInputDevice, so ask the
        // browser directly: a positive maxTouchPoints is how a phone browser tells
        // itself apart from a desktop one.
        return awen_max_touch_points() > 0;
#elif defined(Q_OS_ANDROID) || defined(Q_OS_IOS)
        // A handheld is touch-first by construction, and its touchscreen can
        // register only after the first event — so don't gate on QInputDevice.
        return true;
#else
        // Desktop: a real touchscreen registers a QInputDevice; a plain
        // mouse-and-keyboard box reports none.
        const auto devices = QInputDevice::devices();
        return std::ranges::any_of(
            devices, [](const QInputDevice* device) { return device != nullptr && device->type() == QInputDevice::DeviceType::TouchScreen; });
#endif
    }
}

TouchScreen::TouchScreen(QObject* parent) : QObject{parent}, available_{detectTouchScreen()}
{
}

auto TouchScreen::available() const -> bool
{
    return available_;
}
