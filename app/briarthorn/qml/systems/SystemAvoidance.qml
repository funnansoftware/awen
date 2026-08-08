import awen.entity
import "../model"

// Pillar avoidance: after SystemManeuver has flown the stick, any entity with
// a pillar standing in its path steers around it instead of into it. The
// override is local and temporary — a maneuver keeps flying whatever it wants
// and simply loses the stick for the seconds the wall is ahead — so no
// maneuver, personality or scenario knows the arena geometry exists.
System {
    id: root

    // The world's roster; only entities that fly maneuvers are steered.
    property list<Entity> entities

    // The arena geometry to be flown around.
    property list<Obstacle> obstacles

    // Metres of margin held outside a pillar's wall, so an entity rounds it
    // with room rather than shaving the stone.
    property real clearance: 2000

    // Seconds of straight flight looked ahead on top of the entity's own turn
    // radius: the distance within which a wall is worth turning for.
    property real reaction: 3

    // Bearing error, in degrees, at which the avoidance steer saturates —
    // tighter than a maneuver's, since a wall does not wait.
    readonly property real cutAngle: 20

    function update(dt: real) {
        for (let i = 0; i < root.entities.length; ++i) {
            const entity = root.entities[i];
            if (entity.health <= 0 || entity.maneuvers.length === 0 || entity.speed <= 0)
                continue;
            const pillar = root.blocker(entity);
            if (pillar !== null)
                root.avoid(entity, pillar);
        }
    }

    // The pillar the entity's current heading runs into soonest, or null for
    // a clear path. The reach is measured to where the nose would enter the
    // cleared wall, not to the pillar's centre — a wide pillar has to be seen
    // from outside it, not from within.
    function blocker(entity: Entity): Obstacle {
        const ux = Geo.offsetX(entity.heading, 1);
        const uy = Geo.offsetY(entity.heading, 1);
        const reach = root.lookahead(entity);
        let nearest = null;
        let nearestEntry = Infinity;
        for (let i = 0; i < root.obstacles.length; ++i) {
            const pillar = root.obstacles[i];
            const dx = pillar.posX - entity.posX;
            const dy = pillar.posY - entity.posY;
            const along = dx * ux + dy * uy;
            if (along <= 0)
                continue;
            const wall = pillar.radius + root.clearance;
            const lateral = Math.hypot(dx - along * ux, dy - along * uy);
            if (lateral >= wall)
                continue;
            const entry = along - Math.sqrt(wall * wall - lateral * lateral);
            if (entry <= reach && entry < nearestEntry) {
                nearest = pillar;
                nearestEntry = entry;
            }
        }
        return nearest;
    }

    // How far ahead a wall matters: the radius of the entity's own hardest
    // turn, plus the ground it covers while the turn is being set up.
    function lookahead(entity: Entity): real {
        const rate = entity.turnRate * Math.PI / 180;
        const radius = rate > 0 ? entity.speed / rate : 0;
        return radius + entity.speed * root.reaction;
    }

    // Steers onto the tangent of the pillar's cleared wall, rounding it on
    // whichever side the nose already favours, and yields to the maneuver's
    // own steer when that turns away harder than the tangent asks.
    function avoid(entity: Entity, pillar: Obstacle) {
        const bearing = Geo.bearingFrom(entity.posX, entity.posY, pillar.posX, pillar.posY);
        const range = Geo.distanceFrom(entity.posX, entity.posY, pillar.posX, pillar.posY);
        const wall = pillar.radius + root.clearance;
        const tangent = range > wall ? Math.asin(wall / range) * 180 / Math.PI : 90;
        const side = Geo.wrap180(entity.heading - bearing) >= 0 ? 1 : -1;
        const error = Geo.wrap180(bearing + side * tangent - entity.heading);
        const steer = Math.max(-1, Math.min(1, error / root.cutAngle));
        if (Math.sign(entity.commandedSteer) !== Math.sign(steer) || Math.abs(entity.commandedSteer) < Math.abs(steer))
            entity.commandedSteer = steer;
    }
}
