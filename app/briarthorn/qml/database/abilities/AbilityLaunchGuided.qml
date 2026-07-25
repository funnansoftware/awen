import ".."

// The guided rack: six fire-and-forget rounds, slow to cycle.
AbilityLaunch {
    name: "guided"
    label: qsTr("GUIDED")
    cooldown: 2.5
    charges: 6
    weapon: Classification.Kind.MissileGuided
}
