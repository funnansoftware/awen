find_package(GTest CONFIG REQUIRED)

add_executable(briarthorn-test
    Clock.test.cpp
    CommandBuffer.test.cpp
    Duration.test.cpp
    Entity.test.cpp
    Geo.test.cpp
    Heading.test.cpp
    Movement.test.cpp
    World.test.cpp
)

target_link_libraries(briarthorn-test
    PRIVATE
        briarthorn-game
        GTest::gtest_main
)

# The test binary carries the coverage mapping for the library code linked
# into it; register it so the llvm-coverage target reports against it.
set_property(GLOBAL APPEND PROPERTY PROJECT_COVERAGE_TARGETS briarthorn-test)

include(GoogleTest)
gtest_discover_tests(briarthorn-test
    PROPERTIES
        ENVIRONMENT "LLVM_PROFILE_FILE=${CMAKE_BINARY_DIR}/coverage/briarthorn-test-%p.profraw"
)
