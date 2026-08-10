import QtQml

// The world's entity roster and its spawn authority: the one mutable list
// every system iterates and every view binds. Declared entities (ownship, a
// scenario's craft) are added and removed but never destroyed; entities
// spawned here (missiles, decoys) are destroyed again on despawn.
QtObject {
    id: root

    // Every live entity, in no meaningful order.
    property list<Entity> entities

    // The arena geometry every system tests against and every scope draws —
    // assigned wholesale when a scenario carrying an arena takes the stage,
    // cleared when one without leaves it. Terrain, so no spawn machinery.
    property list<Obstacle> obstacles

    // Entities this world created and therefore destroys.
    property var spawned: new Set()

    // Serial for generated callsigns, so track ids stay unique.
    property int serial: 0

    readonly property Component entityFactory: Component {
        Entity {}
    }

    function add(entity: Entity) {
        root.entities = [...root.entities, entity];
    }

    // Builds an entity of a kind and enrolls it: everything its definition
    // carries — stats, radar cone, ability slots — comes from the database,
    // and props overrides only what this one spawn differs in. prefix names it
    // ("MSL" becomes callsign "MSL 1").
    function spawn(prefix: string, classification: int, props: var): Entity {
        const seed = props !== undefined ? props : {};
        seed.classification = classification;
        seed.callsign = prefix + " " + (++root.serial);
        const entity = root.entityFactory.createObject(root, seed) as Entity;
        root.spawned.add(entity);
        root.add(entity);
        return entity;
    }

    function despawn(entity: Entity) {
        root.entities = root.entities.filter(e => e !== entity);
        if (root.spawned.delete(entity))
            entity.destroy();
    }

    // Sweeps the roster back to one survivor — @p keep stays enrolled, every
    // other entity leaves and the spawned ones are destroyed — and rewinds the
    // callsign serial, so a new game numbers its missiles from one again rather
    // than carrying the last game's count. The count only rewinds once nothing
    // generated is left to collide with, since tracks are keyed by callsign.
    function clear(keep: Entity) {
        const roster = root.entities.slice();
        for (let i = 0; i < roster.length; ++i) {
            if (roster[i] !== keep)
                root.despawn(roster[i]);
        }
        if (root.spawned.size === 0)
            root.serial = 0;
    }
}
