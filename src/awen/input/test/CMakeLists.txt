find_package(GTest CONFIG REQUIRED)

add_executable(awen-input-test
    main.cpp
    Actions.test.cpp
    Axis.test.cpp
)

# The tests import awen.input through the QML engine, so the module is a
# runtime dependency (via the import path below), not a link dependency.
target_compile_definitions(awen-input-test
    PRIVATE
        AWEN_QML_IMPORT_DIR="${QT_QML_OUTPUT_DIRECTORY}"
)
add_dependencies(awen-input-test awen-input)

target_link_libraries(awen-input-test
    PRIVATE
        GTest::gtest
        Qt6::Gui
        Qt6::Qml
)

include(GoogleTest)
gtest_discover_tests(awen-input-test)
