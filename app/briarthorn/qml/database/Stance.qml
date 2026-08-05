import QtQml

// One posture inside a Personality: what it flies (by Maneuvers-registry
// name, so the database imports nothing back), how it holds the trigger, and
// where it may go next. Shared and immutable like every database row.
QtObject {
    id: root

    enum Reference {
        Target,
        Threat
    }

    property string name: ""

    // The maneuver flown, by registry name; "" flies nothing and leaves the
    // last commands standing.
    property string maneuver: ""

    // What the maneuver flies against: the engage target, or the inbound
    // round — which falls back to the target while the sky is clear.
    property int reference: Stance.Reference.Target

    // Fraction of the envelope below priced onto the maneuver's standoff;
    // 0 keeps the maneuver's own default.
    property real standoff: 0
    property int standoffOf: Envelope.Kind.OwnWeapon

    // Trigger posture while current: holdFire mirrors onto engageHold, and a
    // non-negative holdoff repaces the launches (-1 keeps the spawn pace).
    property bool holdFire: false
    property real holdoff: -1

    // Outgoing transitions in priority order, checked after the
    // personality's own.
    property list<Switch> switches
}
