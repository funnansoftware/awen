// Pops an expendable decoy at the invoker: a same-side contact returning
// exactly what the invoker does, placed between it and the round marked
// inbound, so a hostile seeker — which keeps the nearer of two matching
// returns — re-homes on the decoy instead. SystemCountermeasure consumes the
// raised intent, spawns the decoy kind named here and ages it out again.
Ability {
    id: root

    // The decoy kind popped, and the seconds one burns before it despawns.
    property int decoy: Classification.Kind.Decoy
    property real life: 10

    // Metres from the deployer the decoy is ejected to — toward the round it
    // answers, astern with the sky clear, but always this far whichever way
    // it goes. It has to clear the warhead a seeker will bite it with — the
    // round fuzes short of the decoy and the blast reaches further still — or
    // stealing the lock kills the deployer anyway.
    property real ejectRange: 2000

    stationKind: root.decoy
}
