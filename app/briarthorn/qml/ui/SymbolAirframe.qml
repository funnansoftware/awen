import QtQuick.Shapes
import awen.shapes
import "../database"
import "../themes"

// The stores page's airframe: a plan view drawn from the definition row's
// silhouette, falling back to the coarse scope outline for a kind that never
// authored one — so every craft has a stores picture the moment it exists.
ShapePolygon {
    id: root

    // The definition row the drawing reads.
    property Data def: null

    points: root.def === null ? [] : (root.def.silhouette.length > 0 ? root.def.silhouette : root.def.outline)
    fillColor: Style.theme.windowBackground
    strokeColor: Style.theme.factionOwnship
    strokeWidth: 1.5
    joinStyle: ShapePath.RoundJoin
}
