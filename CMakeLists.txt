cmake_minimum_required(VERSION 3.31)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

project(awen)

include(CTest)
include(GNUInstallDirs)

option(ENABLE_COVERAGE "Compile with llvm source-based coverage instrumentation" OFF)

if(ENABLE_COVERAGE)
    if(NOT CMAKE_CXX_COMPILER_ID MATCHES "Clang")
        message(FATAL_ERROR "ENABLE_COVERAGE requires a Clang compiler (using ${CMAKE_CXX_COMPILER_ID}).")
    endif()

    add_compile_options(-fprofile-instr-generate -fcoverage-mapping)
    add_link_options(-fprofile-instr-generate)
endif()

include(cmake/qt-vcpkg-fixup.cmake)
include(cmake/target/apk.cmake)
include(cmake/target/clang-format.cmake)
include(cmake/target/clang-tidy.cmake)

# The framework is built around Qt Quick; the qt manifest feature — set by the
# desktop CMake presets — pulls it in. Builds without the feature (the zig
# build, android, emscripten) skip the framework and the apps fall back to
# their non-Qt rendering edges.
if("qt" IN_LIST VCPKG_MANIFEST_FEATURES)
    find_package(Qt6 6.11 CONFIG REQUIRED COMPONENTS Quick)

    qt_standard_project_setup(REQUIRES 6.11)

    # Collect every qt_add_qml_module output under a single tree so that all
    # in-project QML modules (e.g. awen.entity) are discoverable via a single
    # import path. This is what the auto-generated .qmlls.ini files (and any
    # downstream tooling, such as qmllint or deploy scripts) will reference.
    set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml" CACHE PATH
        "Base output directory for all qt_add_qml_module targets" FORCE)

    # Auto-generate .qmlls.ini next to each QML source directory so the QML
    # language server picks up the correct per-build import paths regardless of
    # platform or preset. See: https://doc.qt.io/qt-6/qtqml-tooling-qmlls.html
    set(QT_QML_GENERATE_QMLLS_INI ON CACHE BOOL "Generate .qmlls.ini for qmlls" FORCE)

    add_subdirectory(src)
endif()

add_subdirectory(app)

# After the subdirectories so targets have registered themselves in the
# PROJECT_COVERAGE_TARGETS global property this script reads.
include(cmake/target/llvm-coverage.cmake)
