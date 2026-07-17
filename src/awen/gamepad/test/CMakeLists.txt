find_package(GTest CONFIG REQUIRED)

add_executable(awen-gamepad-test
    Gamepad.test.cpp
)

# Links ONLY the Qt-free core (not the QML module, not Quick, not the SDL runtime),
# so the coverage report is the translation logic alone. The core carries the SDL
# headers the tests read events and constants from.
target_link_libraries(awen-gamepad-test
    PRIVATE
        awen-gamepad-core
        GTest::gtest_main
)

# The test binary carries the coverage mapping for the core library linked into it;
# register it so the llvm-coverage target reports against it.
set_property(GLOBAL APPEND PROPERTY PROJECT_COVERAGE_TARGETS awen-gamepad-test)

include(GoogleTest)
gtest_discover_tests(awen-gamepad-test
    PROPERTIES
        ENVIRONMENT "LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/coverage/awen-gamepad-test-%p.profraw"
)
