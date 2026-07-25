import QtQml
import "../database"

// The world's entity roster and its spawn authority: the one mutable list
// every system iterates and every view binds. Declared entities (ownship, a
// scenario's craft) are added and removed but never destroyed; entities
// spawned here (missiles, decoys) are destroyed again on despawn.
QtObject {
    id: world

    // Every live entity, in no meaningful order.
    property list<Entity> entities

    // Entities this world created and therefore destroys.
    property var spawned: new Set()

    // Serial for generated callsigns, so track ids stay unique.
    property int serial: 0

    readonly property Component entityFactory: Component {
        Entity {}
    }

    function add(entity: Entity) {
        world.entities = [...world.entities, entity];
    }

    // Builds an entity of a kind and enrolls it: everything its definition
    // carries — stats, radar cone, ability slots — comes from the database,
    // and props overrides only what this one spawn differs in. prefix names it
    // ("MSL" becomes callsign "MSL 1").
    function spawn(prefix: string, classification: int, props: var): Entity {
        const seed = props !== undefined ? props : {};
        seed.classification = classification;
        seed.callsign = prefix + " " + (++world.serial);
        const entity = world.entityFactory.createObject(world, seed) as Entity;
        world.spawned.add(entity);
        world.add(entity);
        return entity;
    }

    function despawn(entity: Entity) {
        world.entities = world.entities.filter(e => e !== entity);
        if (world.spawned.delete(entity))
            entity.destroy();
    }
}
