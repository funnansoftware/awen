import awen.entity
import "../model"

// AI trigger discipline: invokes the entity's named launch ability when its
// target is alive, inside the radar cone and within engageRange — with a
// holdoff between invocations on top of the ability's own cooldown, so the
// magazine is not dumped in one pass.
System {
    id: engage

    // The shooter and what it shoots at.
    required property Entity entity
    required property Entity target

    // The launch ability invoked, by registry name.
    property string ability: "guided"

    // Maximum firing range, metres.
    property real engageRange: 45000

    // Minimum seconds between invocations.
    property real holdoff: 6

    property real timer: 0

    function update(dt: real) {
        engage.timer = Math.max(0, engage.timer - dt);
        if (engage.timer > 0 || engage.target === null || engage.target.health <= 0)
            return;
        const dx = engage.target.posX - engage.entity.posX;
        const dy = engage.target.posY - engage.entity.posY;
        if (Math.hypot(dx, dy) > engage.engageRange)
            return;
        const bearing = Math.atan2(dx, -dy) * 180 / Math.PI;
        const off = (((bearing - engage.entity.heading) % 360) + 540) % 360 - 180;
        if (Math.abs(off) > engage.entity.radarFov / 2)
            return;
        for (let i = 0; i < engage.entity.abilities.length; ++i) {
            const slot = engage.entity.abilities[i];
            if (slot.def.name === engage.ability && slot.ready) {
                slot.activate();
                engage.timer = engage.holdoff;
                return;
            }
        }
    }
}
