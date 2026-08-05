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
        return root.distanceFrom(a.posX, a.posY, b.posX, b.posY);
    }

    // Straight-line distance from one point to another, metres.
    function distanceFrom(x: real, y: real, toX: real, toY: real): real {
        return Math.hypot(toX - x, toY - y);
    }

    // The true bearing from one entity to another.
    function bearing(from: Entity, to: Entity): real {
        return root.bearingFrom(from.posX, from.posY, to.posX, to.posY);
    }

    // The true bearing from one point to another.
    function bearingFrom(x: real, y: real, toX: real, toY: real): real {
        return Math.atan2(toX - x, -(toY - y)) * 180 / Math.PI;
    }

    // An angle folded into [-180, 180), for bearing-error comparisons.
    function wrap180(angle: real): real {
        return ((angle % 360) + 540) % 360 - 180;
    }

    // An angle folded into [0, 360) — the full-circle compass form
    // Entity.heading stores. wrap180 is its signed twin for bearing-error
    // comparisons.
    function wrap360(angle: real): real {
        return ((angle % 360) + 360) % 360;
    }

    // The reciprocal of a bearing — the same line pointed the opposite way,
    // folded into [0, 360). Flying it takes you directly away from whatever
    // the bearing points at.
    function reciprocal(bearing: real): real {
        return root.wrap360(bearing + 180);
    }

    // The perpendicular of a bearing on its right-hand side — a quarter turn
    // clockwise — folded into [0, 360).
    function perpendicularRight(bearing: real): real {
        return root.wrap360(bearing + 90);
    }

    // The perpendicular of a bearing on its left-hand side — a quarter turn
    // anticlockwise — folded into [0, 360).
    function perpendicularLeft(bearing: real): real {
        return root.wrap360(bearing - 90);
    }

    // The axis offsets of a step along a bearing.
    function offsetX(bearing: real, range: real): real {
        return Math.sin(bearing * Math.PI / 180) * range;
    }

    function offsetY(bearing: real, range: real): real {
        return -Math.cos(bearing * Math.PI / 180) * range;
    }
}
