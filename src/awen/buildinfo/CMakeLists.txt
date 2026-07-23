# awen.buildinfo — build metadata for QML. The BuildInfo singleton exposes a
# date-based version stamped when the package is built. The stamp lives in a
# generated header: seeded here at configure time, then refreshed by
# awen-buildinfo-version on every build (rewritten only when the date changes, so
# same-day rebuilds don't recompile).
set(version_template "${CMAKE_CURRENT_SOURCE_DIR}/version.h.in")
set(version_header "${CMAKE_CURRENT_BINARY_DIR}/awen_build_version.h")

# Seed the header at configure time so the first compile has it in hand.
set(VERSION_TEMPLATE "${version_template}")
set(VERSION_HEADER "${version_header}")
include("${CMAKE_CURRENT_SOURCE_DIR}/GenerateVersion.cmake")

# Re-stamp on every build (the target always runs); the configure_file inside the
# script only rewrites the header when the stamped date differs.
add_custom_target(awen-buildinfo-version
    BYPRODUCTS "${version_header}"
    COMMAND ${CMAKE_COMMAND}
        -DVERSION_TEMPLATE=${version_template}
        -DVERSION_HEADER=${version_header}
        -P ${CMAKE_CURRENT_SOURCE_DIR}/GenerateVersion.cmake
    COMMENT "Stamping awen build version"
    VERBATIM
)

awen_add_qml_module(awen-buildinfo
    URI awen.buildinfo
    VERSION 1.0
    QML_FILES
    SOURCES
        BuildInfo.h
        BuildInfo.cpp
)

# BuildInfo.cpp includes the generated header from the binary dir.
target_include_directories(awen-buildinfo PRIVATE ${CMAKE_CURRENT_BINARY_DIR})
add_dependencies(awen-buildinfo awen-buildinfo-version)
