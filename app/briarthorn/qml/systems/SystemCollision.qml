import awen.entity
import "../model"

// Arena collision: any entity flying inside a pillar's wall is wrecked on
// it — health zeroed, so SystemWeapon's reap despawns it and the mission
// judge reads the impact exactly like a kill. Runs after SystemMovement so
// it tests the tick's fresh poses.
System {
    id: root

    // The world whose roster is tested against its arena geometry.
    required property World world

    function update(dt: real) {
        for (let i = 0; i < root.world.obstacles.length; ++i) {
            const pillar = root.world.obstacles[i];
            for (let j = 0; j < root.world.entities.length; ++j) {
                const entity = root.world.entities[j];
                if (entity.health > 0 && Geo.distanceFrom(entity.posX, entity.posY, pillar.posX, pillar.posY) <= pillar.radius)
                    entity.health = 0;
            }
        }
    }
}
