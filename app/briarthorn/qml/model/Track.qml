import QtQml

// One contact in an observer's track picture: the perception of a world
// entity in the observer's frame. Position is polar — range in metres and
// azimuth as a true bearing, degrees clockwise from north, measured at the
// observer. Pure state; SystemDetection keeps it updated.
QtObject {
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
}
