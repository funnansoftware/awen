#pragma once

#include <QtQml/qqmlregistration.h>
#include <QObject>
#include <QString>

namespace awen
{
    /// @brief Build metadata for QML. A singleton — `import awen.buildinfo`, then
    /// read the stamped values:
    ///
    /// @code
    /// import awen.buildinfo
    /// Text { text: BuildInfo.version }
    /// @endcode
    class BuildInfo : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        /// @brief The date-based version stamped when the app was built, `YYYY.MM.DD`.
        Q_PROPERTY(QString version READ version CONSTANT)

    public:
        explicit BuildInfo(QObject* parent = nullptr);

        [[nodiscard]] auto version() const -> QString;

    private:
        QString version_{}; ///< See version.
    };
}
