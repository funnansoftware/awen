import QtQml
import awen.entity
import "../model"

// Sensor sweep: the sole writer of the observer's track picture. Every tick
// each other entity gets a track at its measured azimuth and range; a contact
// inside the radar volume (within half of radarFov off the nose and inside
// sensor range) resolves to its true classification, side and heading,
// anything else stays Unknown with the heading held at its last seen value.
// Tracks update in place — the list itself changes only when a contact first
// appears, so views keyed on it stay stable.
System {
    id: detection

    // The observing entity and the world's entities (the observer is skipped;
    // contacts are keyed by callsign, so callsigns must be unique).
    required property Entity observer
    property list<Entity> entities

    // The track picture, one Track per contact.
    property list<Track> tracks

    readonly property Component trackFactory: Component {
        Track {}
    }

    // Held tracks keyed by contactId, so updates land on stable instances.
    property var held: ({})

    function update(dt: real) {
        let changed = false;
        for (let i = 0; i < detection.entities.length; ++i) {
            const entity = detection.entities[i];
            if (entity === detection.observer)
                continue;
            let track = detection.held[entity.callsign];
            if (track === undefined) {
                track = detection.trackFactory.createObject(detection, {
                    contactId: entity.callsign
                });
                detection.held[entity.callsign] = track;
                changed = true;
            }
            const dx = entity.posX - detection.observer.posX;
            const dy = entity.posY - detection.observer.posY;
            track.range = Math.hypot(dx, dy);
            track.azimuth = ((Math.atan2(dx, -dy) * 180 / Math.PI) % 360 + 360) % 360;
            const seen = detection.detected(track);
            track.classification = seen ? entity.classification : Classification.Kind.Unknown;
            track.side = seen ? entity.side : Side.Kind.Unknown;
            if (seen)
                track.heading = entity.heading;
        }
        if (changed)
            detection.tracks = Object.values(detection.held);
    }

    // Whether a measurement falls inside the observer's radar volume: within
    // half the FOV cone off the nose and inside sensor range.
    function detected(track: Track): bool {
        const off = (((track.azimuth - detection.observer.heading) % 360) + 540) % 360 - 180;
        return Math.abs(off) <= detection.observer.radarFov / 2 && track.range <= detection.observer.sensor;
    }
}
