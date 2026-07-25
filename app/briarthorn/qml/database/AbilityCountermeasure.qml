// Pops an expendable decoy at the invoker: a same-side contact so loud a
// hostile seeker re-homes on it instead. SystemCountermeasure consumes the
// raised intent, spawns the decoy kind named here and ages it out again.
Ability {
    // The decoy kind popped, and the seconds one burns before it despawns.
    property int decoy: Classification.Kind.Decoy
    property real life: 10
}
