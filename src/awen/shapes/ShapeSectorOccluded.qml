import QtQuick
import QtQuick.Shapes
import "bearing.js" as Bearing

// ShapeSector's shadow-cast twin: the same boresight-first wedge, but along
// each bearing the fill stops at the first occluding disc, so the drawn volume
// is what a sensor at the apex can actually see. Occluders are plain {x, y, r}
// rows in source units about a moving apex (ShapeTrail's positionScale
// convention), keeping the module free of app model types.
Shape {
    id: root

    // Wedge reach in px; defaults to the largest circle that keeps the stroke
    // inside the item's bounds.
    property real radius: Math.min(width, height) / 2 - strokeWidth / 2

    // Bearing of the wedge's centre, degrees clockwise from up, and its total
    // angular width; a span of 360 draws an all-round occluded sweep.
    property real angleAt: 0
    property real angleSpan: 60

    // The wedge's apex in item coordinates; defaults to the item's middle.
    property real centerX: width / 2
    property real centerY: height / 2

    // The apex's position in source units and the source-to-px scale, so a
    // static occluder set is assigned once, never rebuilt as the apex moves.
    property real sourceX: 0
    property real sourceY: 0
    property real positionScale: 1

    // The occluding discs: {x, y, r} rows in source units.
    property var occluders: []

    // Uniform ray pitch, degrees. Tangent and centre bearings are inserted
    // exactly per disc, so this paces only the smooth arc stretches.
    property real stepDeg: 3

    property color fillColor: "white"

    property alias strokeColor: path.strokeColor
    property alias strokeWidth: path.strokeWidth

    // The visible region's outline in item px: the apex, then one vertex per
    // swept bearing at min(radius, nearest disc bite), closed back on the
    // apex — or rim-to-rim with no apex for a full-circle span. A disc
    // holding the apex empties the outline: such a sensor sees nothing.
    readonly property list<point> polyline: {
        // A hidden wedge sweeps nothing: bindings evaluate whether or not the
        // item draws, and an app parking a second scope offscreen would
        // otherwise pay for its march every tick.
        if (!visible)
            return [];

        const span = Math.min(angleSpan, 360);
        const full = span >= 360;
        const reach = positionScale > 0 ? radius / positionScale : 0;
        if (reach <= 0 || span <= 0)
            return [];

        // The uniform rays, as offsets from the wedge's start edge; both
        // edges are always sampled exactly, so a straddling disc shortens
        // the edge ray it crosses.
        const step = Math.max(0.1, stepDeg);
        const rays = [];
        if (full) {
            const n = Math.max(8, Math.ceil(360 / step));
            for (let i = 0; i < n; ++i)
                rays.push(i * 360 / n);
        } else {
            const n = Math.max(2, Math.ceil(span / step) + 1);
            for (let i = 0; i < n; ++i)
                rays.push(i * span / (n - 1));
        }

        const start = angleAt - span / 2;
        const insert = b => {
            const rel = Bearing.wrapDeg(b - start);
            if (rel <= span)
                rays.push(rel);
        };

        // Cull to discs that can bite: near rim inside reach and silhouette
        // crossing the wedge. Survivors insert their critical bearings — the
        // doubled tangent pair keeps the shadow's radial edge crisp, and the
        // centre bearing pins the bite's bottom at exactly d - r.
        const ox = [];
        const oy = [];
        const cr = [];
        const c2 = [];
        const occ = occluders || [];
        for (let i = 0; i < occ.length; ++i) {
            const dx = occ[i].x - sourceX;
            const dy = occ[i].y - sourceY;
            const r = occ[i].r;
            const dd = dx * dx + dy * dy;
            const d = Math.sqrt(dd);
            if (d <= r)
                return [];
            if (d - r > reach)
                continue;
            const beta = Math.atan2(dx, -dy) * 180 / Math.PI;
            const alpha = Math.asin(Math.min(1, r / d)) * 180 / Math.PI;
            if (!full && Bearing.distanceDeg(beta, angleAt) > span / 2 + alpha)
                continue;
            ox.push(dx);
            oy.push(dy);
            cr.push(r);
            c2.push(dd);
            insert(beta - alpha - 0.05);
            insert(beta - alpha);
            insert(beta);
            insert(beta + alpha);
            insert(beta + alpha + 0.05);
        }
        rays.sort((a, b) => a - b);

        // Per ray, the polar twin of the closest-point blocking rule: the
        // near ray-disc intersection s - sqrt(r^2 - h^2), with rounding at
        // exact tangency clamped so the rim never flickers past the disc.
        const toRad = Math.PI / 180;
        const out = [];
        if (!full)
            out.push(Qt.point(centerX, centerY));
        for (let i = 0; i < rays.length; ++i) {
            const a = (start + rays[i]) * toRad;
            const ux = Math.sin(a);
            const uy = -Math.cos(a);
            let best = reach;
            for (let k = 0; k < ox.length; ++k) {
                const s = ox[k] * ux + oy[k] * uy;
                if (s <= 0)
                    continue;
                let q = cr[k] * cr[k] - (c2[k] - s * s);
                if (q < 0) {
                    if (q < -1e-7 * cr[k] * cr[k])
                        continue;
                    q = 0;
                }
                const hit = s - Math.sqrt(q);
                if (hit < best)
                    best = hit;
            }
            out.push(Qt.point(centerX + ux * best * positionScale, centerY + uy * best * positionScale));
        }
        out.push(full ? out[0] : Qt.point(centerX, centerY));
        return out;
    }

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: path
        fillColor: root.fillColor
        strokeColor: "transparent"

        PathPolyline {
            path: root.polyline
        }
    }
}
