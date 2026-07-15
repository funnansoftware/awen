project(briarthorn-game)

add_library(${PROJECT_NAME})

# PRIVATE: these translation units are compiled into the archive and linked by
# consumers, not re-propagated as interface sources for every consumer to rebuild.
target_sources(${PROJECT_NAME} PRIVATE
    Clock.cpp
    CommandBuffer.cpp
    Duration.cpp
    Entity.cpp
    Geo.cpp
    Vec2.cpp
    World.cpp
    systems/Movement.cpp
)

target_include_directories(${PROJECT_NAME}
    PUBLIC
        ${CMAKE_CURRENT_SOURCE_DIR}/..
)

# The game core is deliberately free of raylib and every platform library, so it
# links nothing here — that is what lets Briarthorn (and the tests) run headless.

if(BUILD_TESTING AND NOT ANDROID AND NOT EMSCRIPTEN)
    add_subdirectory(test)
endif()
