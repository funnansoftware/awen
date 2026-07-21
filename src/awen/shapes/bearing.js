// Shared bearing-degree helpers: 0 = up (12 o'clock), positive clockwise.
.pragma library

// Wraps a bearing into [0, 360).
function wrapDeg(deg) {
    return ((deg % 360) + 360) % 360;
}

// Shortest angular distance between two bearings, in [0, 180].
function distanceDeg(a, b) {
    const d = Math.abs(wrapDeg(a) - wrapDeg(b));
    return Math.min(d, 360 - d);
}

// The point at bearing angleDeg and distance r from (cx, cy).
function point(cx, cy, angleDeg, r) {
    const a = angleDeg * Math.PI / 180;
    return Qt.point(cx + Math.sin(a) * r, cy - Math.cos(a) * r);
}
