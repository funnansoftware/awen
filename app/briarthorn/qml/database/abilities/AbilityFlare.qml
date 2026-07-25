import ".."

// The flare pod: ten decoys, popped one at a time off no cooldown, each
// burning for ten seconds.
AbilityCountermeasure {
    name: "flare"
    label: qsTr("FLARE")
    charges: 10
    decoy: Classification.Kind.Decoy
    life: 10
}
