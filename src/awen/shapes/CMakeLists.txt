# awen.shapes — declarative instrument primitives on QtQuick.Shapes: arcs,
# rings, gauges, polygons, ticks and connectors. Angles are bearing degrees
# (0 = up, clockwise); text stays with the app, anchored on exposed readouts.
awen_add_qml_module(awen-shapes
    URI awen.shapes
    VERSION 1.0
    # Declared so the configure-time import scan links the Shapes plugin into
    # static (wasm) apps; no app QML imports QtQuick.Shapes directly.
    DEPENDENCIES
        QtQuick.Shapes
    QML_FILES
        bearing.js
        ShapeArc.qml
        ShapeGauge.qml
        ShapeLink.qml
        ShapePolygon.qml
        ShapeReticle.qml
        ShapeRing.qml
        ShapeSector.qml
        ShapeSparkline.qml
        ShapeTicks.qml
)

# Tests run natively only; the web and android presets set BUILD_TESTING=OFF.
if(BUILD_TESTING)
    add_subdirectory(test)
endif()
