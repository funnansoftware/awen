import QtQml

// Base transition row inside a Personality: a pure condition and the stance
// it leads to. One shared instance per use — the dwell clock lives on the
// entity's PersonalityState, only the required seconds live here.
QtObject {
    id: root

    // The destination stance, by name on the same personality.
    property string to: ""

    // Seconds the condition must hold continuously before the switch fires;
    // 0 fires the tick it first holds.
    property real dwell: 0

    // Whether the condition holds against the situation SystemPersonality
    // prices each tick; derived switches override this.
    function holds(s: var): bool {
        return false;
    }
}
