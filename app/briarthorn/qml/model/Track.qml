import QtQml
import "../database"

// One contact in an observer's track picture: the perception of a world
// entity in the observer's frame. Position is polar — range in metres and
// azimuth as a true bearing, degrees clockwise from north, measured at the
// observer. Pure state; SystemDetection keeps it updated.
QtObject {
    id: root

    // Stable identifier (the source entity's callsign).
    property string contactId: ""

    // True bearing to the contact, degrees clockwise from north.
    property real azimuth: 0

    // Range to the contact from the observer, metres.
    property real range: 0

    // The observer's (possibly coarser) classification of the contact.
    property int classification: Classification.Kind.Unknown

    // Perceived allegiance.
    property int side: Side.Kind.Unknown

    // The contact's facing, degrees clockwise from north.
    property real heading: 0

    // The contact's perceived hull, hit points, against the full hull its kind
    // carries. A maxHealth of zero is the no-reading case — a return the sweep
    // has not resolved, or a kind that was never given hull at all.
    property real health: 0
    property real maxHealth: 0

    // The hull reading as a fraction of full, 0..1; zero without a reading.
    readonly property real healthFrac: root.maxHealth > 0 ? Math.max(0, Math.min(1, root.health / root.maxHealth)) : 0
}
