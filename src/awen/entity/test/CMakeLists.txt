find_package(GTest CONFIG REQUIRED)

add_executable(awen-entity-test
    main.cpp
    System.test.cpp
)

# The tests import awen.entity through the QML engine, so the module is a
# runtime dependency (via the import path below), not a link dependency.
target_compile_definitions(awen-entity-test
    PRIVATE
        AWEN_QML_IMPORT_DIR="${QT_QML_OUTPUT_DIRECTORY}"
)
add_dependencies(awen-entity-test awen-entity)

target_link_libraries(awen-entity-test
    PRIVATE
        GTest::gtest
        Qt6::Gui
        Qt6::Qml
)

include(GoogleTest)
gtest_discover_tests(awen-entity-test)
