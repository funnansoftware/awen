import awen.entity
import "../model"

// The one movement-behaviour system: each tick, every entity carrying
// maneuvers has the first engaged one on its list fly it — list order is
// priority — so behaviours mix per entity and adding one is a new Maneuver
// type, never a new system.
System {
    id: root

    // The world's roster; entities without the aspect are passed over.
    property list<Entity> entities

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            for (let j = 0; j < entity.maneuvers.length; ++j) {
                const maneuver = entity.maneuvers[j];
                if (maneuver.engaged) {
                    maneuver.fly(entity, dt);
                    break;
                }
            }
        }
    }
}
