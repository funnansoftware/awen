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
    id: keymap

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
    property var bindings: keymap.load()

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
                pad: {
                    positive: [Gamepad.Button.DpadUp],
                    negative: []
                }
            }
        })

    // Keys a binding may never take: the way in and out of the page, its own
    // traversal keys, and the modifiers — a digital action has no modifier
    // concept and could only fold one as an ordinary key.
    readonly property var blockedKeys: [Qt.Key_Escape, Qt.Key_Back, Qt.Key_Return, Qt.Key_Enter, Qt.Key_Tab, Qt.Key_Backtab, Qt.Key_Delete, Qt.Key_Backspace, Qt.Key_Shift, Qt.Key_Control, Qt.Key_Meta, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_CapsLock]

    // Buttons a binding may never take: the pad's way in and out of the page.
    readonly property var blockedButtons: [Gamepad.Button.Start, Gamepad.Button.East]

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
        const pair = keymap.bindings[name];
        return pair !== undefined ? pair.key : -1;
    }

    function buttonFor(name: string): int {
        const pair = keymap.bindings[name];
        return pair !== undefined ? pair.button : -1;
    }

    // The code lists the actions bind to: empty when unbound, so an unbound
    // ability maps nothing rather than matching a sentinel code.
    function keyCodes(name: string): var {
        const code = keymap.keyFor(name);
        return code > 0 ? [code] : [];
    }

    function buttonCodes(name: string): var {
        const code = keymap.buttonFor(name);
        return code >= 0 ? [code] : [];
    }

    // Whether a control is spoken for by the flight map or by the page itself,
    // and so cannot be captured.
    function reserved(pad: bool, code: int): bool {
        if ((pad ? keymap.blockedButtons : keymap.blockedKeys).includes(code))
            return true;
        const channel = pad ? "pad" : "key";
        for (const axis in keymap.flight) {
            const map = keymap.flight[axis][channel];
            if (map.positive.includes(code) || map.negative.includes(code))
                return true;
        }
        return false;
    }

    // Binds one control to one ability, exclusively: whatever other ability held
    // it loses it, so one press can never post two intents. Returns whether the
    // control was taken, and remembers which ability paid for it. Key code 0 is
    // refused with the negatives — no keyboard produces it, so a binding on it
    // would be dead but still live to a synthesised event.
    function bind(name: string, pad: bool, code: int): bool {
        if (name === "" || code <= 0 || keymap.reserved(pad, code))
            return false;
        const channel = pad ? "button" : "key";
        const next = keymap.copy(keymap.bindings);
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
        keymap.displaced = taken;
        keymap.displacedPad = pad;
        keymap.apply(next);
        return true;
    }

    // Leaves an ability with nothing on one device.
    function unbind(name: string, pad: bool) {
        if (name === "" || keymap.bindings[name] === undefined)
            return;
        const next = keymap.copy(keymap.bindings);
        next[name][pad ? "button" : "key"] = -1;
        keymap.displaced = "";
        keymap.apply(next);
    }

    // Returns every ability to the controls its definition ships with.
    function reset() {
        keymap.displaced = "";
        keymap.apply(keymap.defaults());
    }

    // Publishes a new table and stores it. The whole object is replaced, not
    // edited, so every binding reading keyCodes()/buttonCodes() re-evaluates.
    function apply(next: var) {
        keymap.bindings = next;
        keymap.save();
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
        const shipped = keymap.defaults();
        const diff = {};
        for (const name in keymap.bindings) {
            const pair = keymap.bindings[name];
            const base = shipped[name];
            if (base === undefined || pair.key !== base.key || pair.button !== base.button)
                diff[name] = [pair.key, pair.button];
        }
        keymap.store.setValue("abilities", JSON.stringify(diff));
    }

    // The shipped table with the saved differences overlaid row by row, so one
    // bad row costs that row and not the whole keymap. Returns rather than
    // assigns, so it can seed bindings from its own initialiser.
    function load(): var {
        const table = keymap.defaults();
        let saved = null;
        try {
            saved = JSON.parse(keymap.store.value("abilities", "{}"));
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
        const name = keymap.enumName(Qt.Key, code, "Key_");
        if (name !== "")
            return name;
        // A layout key outside Qt::Key arrives as its own code point; anything
        // else shows as its number, so a cap is never blank.
        return code > 0x7e && code <= 0xffff ? String.fromCharCode(code).toUpperCase() : qsTr("KEY %1").arg(code);
    }

    function buttonLabel(code: int): string {
        if (code < 0)
            return "";
        const marked = keymap.padNames[code];
        if (marked !== undefined)
            return marked;
        const name = keymap.enumName(Gamepad.Button, code, "");
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
