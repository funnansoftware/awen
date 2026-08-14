import QtQml

// One piece of arena geometry: an impassable pillar, a disc in world metres.
// Pure state — SystemCollision wrecks entities on it, the radar systems lose
// line of sight behind it and the scope draws it as terrain.
QtObject {
    id: root

    // Centre in world metres (1 px = 1 m, +x east, +y south).
    property real posX: 0
    property real posY: 0

    // The disc's radius, metres.
    property real radius: 1000

    // The side whose air defences this piece is keyed to; Unknown — the
    // default — is plain rock, in everyone's way. A battery's screens name
    // its own side, so the set behind them shoots out through ground the
    // attacker can neither see nor shoot through, which is the whole point
    // of a screen.
    property int transparentTo: Side.Kind.Unknown

    // Whether this piece stands in a given entity's way, for sight and for
    // passage both — a barrier that stopped a round it could not see would be
    // two rules wearing one name. Only the network that keeps a screen sees
    // through it: the batteries of its side and the rounds they launch. That
    // side's own aircraft are blocked like anyone else, because a fighter
    // that could vanish behind one while still shooting out of it would be
    // unkillable rather than defended.
    function opaqueTo(entity: Entity): bool {
        if (entity.side !== root.transparentTo)
            return true;
        return !(entity.sentry || (entity.owner !== null && entity.owner.sentry));
    }
}
