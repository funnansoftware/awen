pragma Singleton

import QtCore
import QtQuick

// The chrome every view draws through: the palette in force, and the palettes
// on offer. Each row lives one per file beside this one and registers in the
// single list below, so adding a theme is a new file and one line here. Every
// colour in the interface reads back through theme, so one assignment to
// themeName restyles the whole game — the reads are all bindings.
QtObject {
    id: root

    // The on-disk copy. Declared before themeName, whose initialiser reads it —
    // that order is load-bearing, and loading in an initialiser rather than at
    // completion is what keeps the first frame off the wrong palette.
    readonly property Settings store: Settings {
        category: "display"
    }

    // The registration index. Order is the order the settings page lists them,
    // and the first row is what an unrecognised choice falls back to.
    readonly property list<Theme> themes: [
        ThemeAurora {},
        ThemeCatppuccinMocha {}
    ]

    // The palette's own name, as stored. Empty is "never chosen" and resolves
    // exactly as a name this build no longer ships does — through the fallback.
    // Written through select(), never assigned: a bare assignment applies and
    // is then forgotten on quit.
    property string themeName: root.store.value("theme", "")

    readonly property Theme theme: root.themeFor(root.themeName)

    // Which HUD composition the duel draws: the shipped overlay, or the tiled
    // portal layout. Stored as a name rather than a flag, so a third layout —
    // the deferred narrow-screen collapse — is a new value, not a second bool.
    // Written through selectHud(), like the palette.
    property string hudName: root.store.value("hud", "overlay")
    readonly property bool hudTiled: root.hudName === "tiled"

    // The instrument typeface: the first of these the system actually has.
    // Naming Consolas alone kept windows right but left macOS and linux to
    // substitute a face on their own, warning about the missing family and
    // paying for a font-alias sweep at startup. The QML font value type takes
    // one family, not a fallback list, so resolve it here instead.
    readonly property string monospace: {
        const preferred = ["Consolas", "Menlo", "DejaVu Sans Mono"];
        const available = Qt.fontFamilies();
        for (const family of preferred) {
            if (available.includes(family))
                return family;
        }
        return "monospace";
    }

    // Puts a palette in force and remembers it. Written through at once and
    // synced: a web build's tab can close without ever running a destructor.
    function select(name: string) {
        root.themeName = name;
        root.store.setValue("theme", name);
        root.store.sync();
    }

    // Puts a HUD layout in force and remembers it, same shape as select().
    function selectHud(name: string) {
        root.hudName = name;
        root.store.setValue("hud", name);
        root.store.sync();
    }

    // The row a name asks for, or the first — so a store holding a palette this
    // build dropped renders in the shipped one rather than in nothing.
    function themeFor(name: string): Theme {
        for (let i = 0; i < root.themes.length; ++i) {
            if (root.themes[i].name === name)
                return root.themes[i];
        }
        return root.themes[0];
    }
}
