import awen.entity
import "../model"

// The win/lose engine: latches the duel's outcome from live model state —
// defeat when the player's hull is gone, victory when the target's is. Once
// terminal it holds, so a mutual kill the same tick cannot flip a result,
// and the shell reads the latch to freeze the game behind the end screen.
// Fuel starvation is deliberately not a loss yet: the current fuel economy
// drains a full-throttle tank before the merge, so that condition waits on
// the fuel tuning pass. Ports briardart's SystemMission.
System {
    id: root

    enum Status {
        Ongoing,
        Victory,
        Defeat
    }

    // The player's craft and the craft whose destruction wins the duel.
    required property Entity player
    required property Entity target

    // The latched outcome.
    property int status: SystemMission.Status.Ongoing

    function update(dt: real) {
        if (root.status !== SystemMission.Status.Ongoing)
            return;
        if (root.player.health <= 0)
            root.status = SystemMission.Status.Defeat;
        else if (root.target.health <= 0)
            root.status = SystemMission.Status.Victory;
    }

    // Rearms the engine for a fresh duel.
    function reset() {
        root.status = SystemMission.Status.Ongoing;
    }
}
