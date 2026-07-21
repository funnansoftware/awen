find_package(GTest CONFIG REQUIRED)

add_executable(awen-shapes-test
    main.cpp
    ShapeArc.test.cpp
    ShapeGauge.test.cpp
    ShapeLink.test.cpp
    ShapePolygon.test.cpp
    ShapeRing.test.cpp
    ShapeSparkline.test.cpp
    ShapeTicks.test.cpp
)

# The tests import awen.shapes through the QML engine, so the module is a
# runtime dependency (via the import path below), not a link dependency.
target_compile_definitions(awen-shapes-test
    PRIVATE
        AWEN_QML_IMPORT_DIR="${QT_QML_OUTPUT_DIRECTORY}"
)
add_dependencies(awen-shapes-test awen-shapes)

target_link_libraries(awen-shapes-test
    PRIVATE
        GTest::gtest
        Qt6::Gui
        Qt6::Qml
)

include(GoogleTest)
gtest_discover_tests(awen-shapes-test)
