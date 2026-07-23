#pragma once

#include <QtQml/qqmlregistration.h>
#include <QObject>

namespace awen
{
    /// @brief Reports whether the running device is touch-driven, so QML can gate
    /// on-screen touch controls to where they belong. A singleton — `import
    /// awen.input`, then read the flag:
    ///
    /// @code
    /// import awen.input
    /// Joystick {
    ///     visible: TouchScreen.available
    /// }
    /// @endcode
    ///
    /// True on a phone or tablet (native or a mobile browser) and on a desktop
    /// with a genuine touchscreen; false on a plain mouse-and-keyboard box.
    class TouchScreen : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        /// @brief True when the device has a touchscreen. Resolved once, at first
        /// use — a device gained or lost after that is not reflected.
        Q_PROPERTY(bool available READ available CONSTANT)

    public:
        explicit TouchScreen(QObject* parent = nullptr);

        [[nodiscard]] auto available() const -> bool;

    private:
        bool available_{false}; ///< See available.
    };
}
