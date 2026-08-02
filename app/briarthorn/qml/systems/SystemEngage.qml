import awen.entity
import "../database"
import "../model"

// AI trigger discipline: invokes the entity's named launch ability when its
// target is alive, inside the radar cone and within engageRange — with a
// holdoff between invocations on top of the ability's own cooldown, so the
// magazine is not dumped in one pass.
System {
    id: root

    // The shooter and what it shoots at.
    required property Entity entity
    required property Entity target

    // The launch ability invoked, by registry name, and the round it spawns;
    // the cast is null for a name that is not a launch at all.
    property string ability: "guided"
    readonly property AbilityLaunch def: Abilities.defFor(root.ability) as AbilityLaunch
    readonly property DataWeapon round: root.def ? Database.weaponDataFor(root.def.weapon) : null

    // Maximum firing range, metres: by default as far as that round can
    // physically fly, so the envelope tracks the weapon's own tuning.
    property real engageRange: root.round ? root.round.reach : 0

    // Minimum seconds between invocations.
    property real holdoff: 6

    property real timer: 0

    function update(dt: real) {
        root.timer = Math.max(0, root.timer - dt);
        if (root.timer > 0 || root.target === null || root.target.health <= 0)
            return;
        const dx = root.target.posX - root.entity.posX;
        const dy = root.target.posY - root.entity.posY;
        if (Math.hypot(dx, dy) > root.engageRange)
            return;
        const bearing = Math.atan2(dx, -dy) * 180 / Math.PI;
        const off = (((bearing - root.entity.heading) % 360) + 540) % 360 - 180;
        if (Math.abs(off) > root.entity.radarFov / 2)
            return;
        for (let i = 0; i < root.entity.abilities.length; ++i) {
            const slot = root.entity.abilities[i];
            if (slot.def.name === root.ability && slot.ready) {
                slot.activate();
                root.timer = root.holdoff;
                return;
            }
        }
    }
}
