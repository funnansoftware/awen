import QtQuick
import ".."

// The unknown-contact row: what the scope plots for anything a sensor has not
// resolved, and the fallback every render lookup falls back to. Presentation
// only — a bare Data, so nothing can spawn it.
Data {
    id: root

    classification: Classification.Kind.Unknown
    outline: [Qt.point(0, -0.5), Qt.point(0.35, 0), Qt.point(0, 0.5), Qt.point(-0.35, 0)]
    label: qsTr("UNK")
}
