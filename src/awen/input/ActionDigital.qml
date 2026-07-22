import QtQml

// An action folding held digital inputs into a signed contribution: +1 while
// any positive code is held, -1 for any negative one, 0 at rest or when the
// two cancel. Subtypes route their event channel into press() and release().
Action {
    id: digital

    // The input codes driving the contribution up and down.
    property list<int> positive
    property list<int> negative

    // Held state per code, written by press() and release().
    property var held: ({})

    // Rest means nothing held, not just a zero value.
    function reset() {
        digital.held = ({});
        digital.refresh();
    }

    function press(code: int): bool {
        if (!digital.mapped(code))
            return false;
        digital.held[code] = true;
        digital.refresh();
        return true;
    }

    function release(code: int): bool {
        if (!digital.mapped(code))
            return false;
        digital.held[code] = false;
        digital.refresh();
        return true;
    }

    function mapped(code: int): bool {
        return digital.positive.includes(code) || digital.negative.includes(code);
    }

    function refresh() {
        const down = codes => codes.some(code => digital.held[code] === true);
        digital.value = (down(digital.positive) ? 1 : 0) - (down(digital.negative) ? 1 : 0);
    }
}
