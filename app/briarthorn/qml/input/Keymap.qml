import QtCore
import QtQml
import awen.gamepad
import "../database"

// The player's ability controls: which key and which controller button invoke
// each registered ability, seeded from what every definition ships bound to and
// overlaid with whatever the settings page has rebound. The flight controls are
// listed here too, read-only, so a capture can refuse a control the ship
// already flies on. Every live binding reads back through here, so one
// assignment to bindings re-pushes the whole set onto the live actions.
QtObject {
    id: root

    // The on-disk copy: one JSON string under the input category. Declared
    // before bindings, whose initialiser reads it — that order is load-bearing.
    readonly property Settings store: Settings {
        category: "input"
    }

    // Whether a write is expected to survive the process. QSettings names its
    // store from the application identity and keeps nothing without one, so a
    // build that set none rebinds fine and forgets on quit; the settings page
    // says so rather than lying about it.
    readonly property bool available: Qt.application.organization !== "" || Qt.application.domain !== ""

    // Every registered ability's controls, name to { key, button }; -1 is
    // unbound. Loaded in the initialiser and not at completion: an object held
    // in a property completes after the file that holds it, so a deferred load
    // leaves the whole first turn on defaults.
    property var bindings: root.load()

    // The ability whose binding the last bind() took away, and on which device.
    // The settings page marks that cap, so a steal is never silent.
    property string displaced: ""
    property bool displacedPad: false

    // The flight controls, fixed. They are not rebindable, but they are listed
    // so a capture can refuse their codes: the router fans every event to every
    // action, so an ability sharing W would thrust as well as fire.
    readonly property var flight: ({
            steer: {
                key: {
                    positive: [Qt.Key_D, Qt.Key_Right],
                    negative: [Qt.Key_A, Qt.Key_Left]
                },
                pad: {
                    positive: [Gamepad.Button.DpadRight],
                    negative: [Gamepad.Button.DpadLeft]
                }
            },
            throttle: {
                key: {
                    positive: [Qt.Key_W, Qt.Key_Up],
                    negative: []
                },
                // No button of its own: the d-pad's vertical ranges the scope
                // and the left stick already throttles by how far it is pushed.
                pad: {
                    positive: [],
                    negative: []
                }
            }
        })

    // The scope's range control, fixed like the flight map and listed for the
    // same reason: the d-pad's vertical steps the picture in and out, and a
    // capture must refuse those the way it refuses a flight control.
    readonly property var range: ({
            key: {
                positive: [],
                negative: []
            },
            pad: {
                positive: [Gamepad.Button.DpadUp],
                negative: [Gamepad.Button.DpadDown]
            }
        })

    // Keys a binding may never take: the way in and out of the page, its own
    // traversal keys, and the modifiers — a digital action has no modifier
    // concept and could only fold one as an ordinary key.
    readonly property list<int> blockedKeys: [Qt.Key_Escape, Qt.Key_Back, Qt.Key_Return, Qt.Key_Enter, Qt.Key_Tab, Qt.Key_Backtab, Qt.Key_Delete, Qt.Key_Backspace, Qt.Key_Shift, Qt.Key_Control, Qt.Key_Meta, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_CapsLock]

    // Buttons a binding may never take: the pad's way in and out of the page.
    readonly property list<int> blockedButtons: [Gamepad.Button.Start, Gamepad.Button.East]

    // Controller buttons name their position; the faces and shoulders read
    // better as what is printed on the pad in the player's hands.
    readonly property var padNames: ({
            [Gamepad.Button.South]: "A",
            [Gamepad.Button.East]: "B",
            [Gamepad.Button.West]: "X",
            [Gamepad.Button.North]: "Y",
            [Gamepad.Button.LeftShoulder]: "LB",
            [Gamepad.Button.RightShoulder]: "RB"
        })

    function keyFor(name: string): int {
        const pair = root.bindings[name];
        return pair !== undefined ? pair.key : -1;
    }

    function buttonFor(name: string): int {
        const pair = root.bindings[name];
        return pair !== undefined ? pair.button : -1;
    }

    // The code lists the actions bind to: empty when unbound, so an unbound
    // ability maps nothing rather than matching a sentinel code.
    function keyCodes(name: string): var {
        const code = root.keyFor(name);
        return code > 0 ? [code] : [];
    }

    function buttonCodes(name: string): var {
        const code = root.buttonFor(name);
        return code >= 0 ? [code] : [];
    }

    // Whether a control is spoken for by a fixed map or by the page itself,
    // and so cannot be captured.
    function reserved(pad: bool, code: int): bool {
        if ((pad ? root.blockedButtons : root.blockedKeys).includes(code))
            return true;
        const channel = pad ? "pad" : "key";
        const fixed = [root.range];
        for (const axis in root.flight)
            fixed.push(root.flight[axis]);
        for (let i = 0; i < fixed.length; ++i) {
            const map = fixed[i][channel];
            if (map.positive.includes(code) || map.negative.includes(code))
                return true;
        }
        return false;
    }

    // Binds one control to one ability, exclusively: whatever other ability held
    // it loses it, so one press can never post two intents. Returns whether the
    // control was taken, and remembers which ability paid for it. Key code 0 is
    // refused with the negatives — no keyboard produces it, only synthesised
    // events — but button 0 is South, a face button the loadout ships bindings
    // on, so the pad floor alone is 0.
    function bind(name: string, pad: bool, code: int): bool {
        const floor = pad ? 0 : 1;
        if (name === "" || code < floor || root.reserved(pad, code))
            return false;
        const channel = pad ? "button" : "key";
        const next = root.copy(root.bindings);
        let taken = "";
        for (const other in next) {
            if (other !== name && next[other][channel] === code) {
                next[other][channel] = -1;
                taken = other;
            }
        }
        if (next[name] === undefined)
            next[name] = {
                key: -1,
                button: -1
            };
        next[name][channel] = code;
        root.displaced = taken;
        root.displacedPad = pad;
        root.apply(next);
        return true;
    }

    // Leaves an ability with nothing on one device.
    function unbind(name: string, pad: bool) {
        if (name === "" || root.bindings[name] === undefined)
            return;
        const next = root.copy(root.bindings);
        next[name][pad ? "button" : "key"] = -1;
        root.displaced = "";
        root.apply(next);
    }

    // Returns every ability to the controls its definition ships with.
    function reset() {
        root.displaced = "";
        root.apply(root.defaults());
    }

    // Publishes a new table and stores it. The whole object is replaced, not
    // edited, so every binding reading keyCodes()/buttonCodes() re-evaluates.
    function apply(next: var) {
        root.bindings = next;
        root.save();
    }

    // What the game ships with: every ability on the controls its own
    // definition names, so a new ability needs no entry anywhere here.
    function defaults(): var {
        const table = {};
        const rows = Abilities.registry;
        for (let i = 0; i < rows.length; ++i)
            table[rows[i].name] = {
                key: rows[i].defaultKey,
                button: rows[i].defaultButton
            };
        return table;
    }

    // Persists only what differs from the shipped table, written through at
    // once: a web build's tab can close without ever running a destructor.
    function save() {
        const shipped = root.defaults();
        const diff = {};
        for (const name in root.bindings) {
            const pair = root.bindings[name];
            const base = shipped[name];
            if (base === undefined || pair.key !== base.key || pair.button !== base.button)
                diff[name] = [pair.key, pair.button];
        }
        root.store.setValue("abilities", JSON.stringify(diff));
    }

    // The shipped table with the saved differences overlaid row by row, so one
    // bad row costs that row and not the whole keymap. Returns rather than
    // assigns, so it can seed bindings from its own initialiser.
    function load(): var {
        const table = root.defaults();
        let saved = null;
        try {
            saved = JSON.parse(root.store.value("abilities", "{}"));
        } catch (error) {
            console.warn("Keymap: unreadable saved controls, keeping the shipped table —", error);
            return table;
        }
        if (saved === null || typeof saved !== "object")
            return table;
        for (const name in saved) {
            const pair = saved[name];
            if (Array.isArray(pair) && pair.length === 2 && Number.isInteger(pair[0]) && Number.isInteger(pair[1]))
                table[name] = {
                    key: pair[0],
                    button: pair[1]
                };
            else
                console.warn("Keymap: ignoring a malformed binding for \"" + name + "\"");
        }
        return table;
    }

    // Player-facing name for a key: the printable character where there is one,
    // else the Qt.Key enumerator with its prefix stripped. Qt offers no other
    // reverse lookup — the enum names are not enumerable from QML.
    function keyLabel(code: int): string {
        if (code <= 0)
            return "";
        if (code >= 0x21 && code <= 0x7e)
            return String.fromCharCode(code);
        const name = root.enumName(Qt.Key, code, "Key_");
        if (name !== "")
            return name;
        // A layout key outside Qt::Key arrives as its own code point; anything
        // else shows as its number, so a cap is never blank.
        return code > 0x7e && code <= 0xffff ? String.fromCharCode(code).toUpperCase() : qsTr("KEY %1").arg(code);
    }

    function buttonLabel(code: int): string {
        if (code < 0)
            return "";
        const marked = root.padNames[code];
        if (marked !== undefined)
            return marked;
        const name = root.enumName(Gamepad.Button, code, "");
        return name !== "" ? name : qsTr("BTN %1").arg(code);
    }

    // The first name an enum carries for a code, stripped and upper-cased, or
    // empty when it carries none: the helper throws rather than returning
    // anything, and Qt.Key_Space aliases Qt.Key_Any, so the list is taken in
    // order rather than through the singular form.
    function enumName(type: var, code: int, prefix: string): string {
        try {
            return Qt.enumValueToStrings(type, code)[0].replace(prefix, "").toUpperCase();
        } catch (error) {
            return "";
        }
    }

    function copy(table: var): var {
        const out = {};
        for (const name in table)
            out[name] = {
                key: table[name].key,
                button: table[name].button
            };
        return out;
    }
}
