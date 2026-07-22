find_package(GTest CONFIG REQUIRED)

add_executable(awen-command-test
    main.cpp
    Command.test.cpp
    CommandQueue.test.cpp
    Store.test.cpp
)

# The tests import awen.command through the QML engine, so the module is a
# runtime dependency (via the import path below), not a link dependency.
target_compile_definitions(awen-command-test
    PRIVATE
        AWEN_QML_IMPORT_DIR="${QT_QML_OUTPUT_DIRECTORY}"
)
add_dependencies(awen-command-test awen-command)

target_link_libraries(awen-command-test
    PRIVATE
        GTest::gtest
        Qt6::Gui
        Qt6::Qml
)

include(GoogleTest)
gtest_discover_tests(awen-command-test)
