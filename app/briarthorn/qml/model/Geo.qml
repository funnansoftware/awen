pragma Singleton

import QtQml

// Shared world geometry on the game's frame — bearings in degrees clockwise
// from north, +x east, +y south, distances in metres — so behaviour code
// states its intent and never re-derives the trigonometry. Ports briardart's
// Geo.
QtObject {
    id: root

    // Straight-line distance between two entities, metres.
    function distance(a: Entity, b: Entity): real {
        return Math.hypot(b.posX - a.posX, b.posY - a.posY);
    }

    // The true bearing from one entity to another.
    function bearing(from: Entity, to: Entity): real {
        return Math.atan2(to.posX - from.posX, -(to.posY - from.posY)) * 180 / Math.PI;
    }

    // An angle folded into (-180, 180], for bearing-error comparisons.
    function wrap180(angle: real): real {
        return ((angle % 360) + 540) % 360 - 180;
    }

    // The axis offsets of a step along a bearing.
    function offsetX(bearing: real, range: real): real {
        return Math.sin(bearing * Math.PI / 180) * range;
    }

    function offsetY(bearing: real, range: real): real {
        return -Math.cos(bearing * Math.PI / 180) * range;
    }
}
