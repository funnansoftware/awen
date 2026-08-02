import QtQml

// An action folding held digital inputs into a signed contribution: +1 while
// any positive code is held, -1 for any negative one, 0 at rest or when the
// two cancel. Subtypes route their event channel into press() and release().
Action {
    id: root

    // The input codes driving the contribution up and down.
    property list<int> positive
    property list<int> negative

    // Held state per code, written by press() and release().
    property var held: ({})

    // A rebind drops the held state along with the old codes: press() and
    // release() both early-return on an unmapped code, so the release of a code
    // just unbound never arrives and would pin the contribution for good.
    onPositiveChanged: root.reset()
    onNegativeChanged: root.reset()

    // Rest means nothing held, not just a zero value.
    function reset() {
        root.held = ({});
        root.refresh();
    }

    function press(code: int): bool {
        if (!root.mapped(code))
            return false;
        root.held[code] = true;
        root.refresh();
        return true;
    }

    function release(code: int): bool {
        if (!root.mapped(code))
            return false;
        root.held[code] = false;
        root.refresh();
        return true;
    }

    function mapped(code: int): bool {
        return root.positive.includes(code) || root.negative.includes(code);
    }

    function refresh() {
        const down = codes => codes.some(code => root.held[code] === true);
        root.value = (down(root.positive) ? 1 : 0) - (down(root.negative) ? 1 : 0);
    }
}
