import QtQml
import "../database"

// One personality as carried by an entity: the shared definition row plus
// every mutable per-entity thing — current stance, the dwell clock and the
// live maneuvers the stances fly. SystemPersonality is the only writer, so
// all of it advances on sim time and freezes with the tick.
QtObject {
    id: root

    // The personality definition this mind runs; null seats an unregistered
    // name, warned once at attach and skipped ever after.
    property Personality def: null

    // The current stance, a shared immutable row reference.
    property Stance stance: null

    // The switch accumulating dwell and its clock; a different switch coming
    // up first resets the clock.
    property Switch pending: null
    property real dwell: 0

    // The entity's engageHoldoff captured at attach, restored by stances
    // that do not repace it.
    property real baseHoldoff: 6

    // The entity's engageAbility captured at attach, restored by stances
    // that do not name one of their own.
    property string baseAbility: "guided"

    // One live maneuver per stance in definition order, null where a stance
    // flies nothing — a JS array, because a QML list cannot hold the gaps.
    property var maneuvers: []

    // The live maneuver a stance flies, or null.
    function maneuverFor(stance: Stance): Maneuver {
        const i = root.def.stances.indexOf(stance);
        return i >= 0 ? root.maneuvers[i] : null;
    }
}
