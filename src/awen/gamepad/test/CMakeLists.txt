find_package(GTest CONFIG REQUIRED)

add_executable(awen-gamepad-test
    Gamepad.test.cpp
)

# Links only the Qt-free core, so the coverage report is the translation logic
# alone (no SDL/QML glue).
target_link_libraries(awen-gamepad-test
    PRIVATE
        awen-gamepad-core
        GTest::gtest_main
)

# Register so the llvm-coverage target reports against this binary.
set_property(GLOBAL APPEND PROPERTY PROJECT_COVERAGE_TARGETS awen-gamepad-test)

include(GoogleTest)
gtest_discover_tests(awen-gamepad-test
    PROPERTIES
        ENVIRONMENT "LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/coverage/awen-gamepad-test-%p.profraw"
)
