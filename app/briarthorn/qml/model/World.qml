import QtQml

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

    // Builds an entity from properties and enrolls it; prefix names it
    // ("MSL" becomes callsign "MSL 1").
    function spawn(prefix: string, props: var): Entity {
        props.callsign = prefix + " " + (++world.serial);
        const entity = world.entityFactory.createObject(world, props);
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
