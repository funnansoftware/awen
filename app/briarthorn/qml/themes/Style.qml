pragma Singleton

import QtQuick

QtObject {
    property var theme: Aurora {}

    // The instrument typeface: the first of these the system actually has.
    // Naming Consolas alone kept windows right but left macOS and linux to
    // substitute a face on their own, warning about the missing family and
    // paying for a font-alias sweep at startup. The QML font value type takes
    // one family, not a fallback list, so resolve it here instead.
    readonly property string monospace: {
        const preferred = ["Consolas", "Menlo", "DejaVu Sans Mono"];
        const available = Qt.fontFamilies();
        for (const family of preferred)
        {
            if (available.includes(family))
                return family;
        }
        return "monospace";
    }
}
