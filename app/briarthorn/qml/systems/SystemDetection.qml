import QtQml
import awen.entity
import "../database"
import "../model"

// Sensor sweep: the sole writer of the observer's track picture. Every tick
// each other entity gets a track at its measured azimuth and range; a contact
// inside the radar volume (within half of radarFov off the nose and inside the
// detection range its sensor rating affords) resolves to its true
// classification, side, heading and hull condition, anything else stays
// Unknown with the heading held at its last seen value and no hull reading.
// The observer's own launches (missiles, decoys) are datalinked: always
// resolved, no radar volume needed. A decoy of any side classifies without the
// sweep — it burns, so it plots as a flare wherever it is — but keeps its side
// unresolved, so the scope reads the burn rather than who dropped it.
// Tracks update in place — the list itself changes only when a contact first
// appears, so views keyed on it stay stable.
System {
    id: root

    // The observing entity and the world's entities (the observer is skipped;
    // contacts are keyed by callsign, so callsigns must be unique).
    required property Entity observer
    property list<Entity> entities

    // The arena geometry radar cannot see through.
    property list<Obstacle> obstacles

    // The track picture, one Track per contact.
    property list<Track> tracks

    readonly property Component trackFactory: Component {
        Track {}
    }

    // Held tracks keyed by contactId, so updates land on stable instances.
    property var held: ({})

    function update(dt: real) {
        let changed = false;
        const present = new Set();
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity === root.observer)
                continue;
            present.add(entity.callsign);
            let track = root.held[entity.callsign];
            if (track === undefined) {
                track = root.trackFactory.createObject(root, {
                    contactId: entity.callsign
                });
                root.held[entity.callsign] = track;
                changed = true;
            }
            track.range = Geo.distance(root.observer, entity);
            track.azimuth = Geo.wrap360(Geo.bearing(root.observer, entity));
            const seen = entity.owner === root.observer || root.detected(track, entity);
            // A decoy is built to be seen: it burns, and a burning flare is
            // its own emitter on every scope, radar or none. So its kind
            // resolves for any observer while the rest of the contact still
            // rides on the sweep — the burn reads without whose it is.
            track.classification = seen || entity.decoy ? entity.classification : Classification.Kind.Unknown;
            track.side = seen ? entity.side : Side.Kind.Unknown;
            // Condition rides with the resolution: lose the contact and the
            // hull reading goes with it rather than freezing on the scope.
            track.health = seen ? entity.health : 0;
            track.maxHealth = seen ? entity.maxHealth : 0;
            if (seen)
                track.heading = entity.heading;
        }
        // Contacts gone from the world (detonated, killed, burned out) drop
        // from the picture with their entity.
        for (const contactId in root.held) {
            if (!present.has(contactId)) {
                root.held[contactId].destroy();
                delete root.held[contactId];
                changed = true;
            }
        }
        if (changed)
            root.tracks = Object.values(root.held);
    }

    // Whether a measurement falls inside the observer's radar volume — within
    // half the FOV cone off the nose and inside sensor range — with the line
    // to the contact clear of the arena's pillars.
    function detected(track: Track, entity: Entity): bool {
        const off = Geo.wrap180(track.azimuth - root.observer.heading);
        return Math.abs(off) <= root.observer.radarFov / 2 && track.range <= root.observer.detectionRange && Geo.lineOfSight(root.observer, entity, root.obstacles);
    }
}
