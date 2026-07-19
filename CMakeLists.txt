cmake_minimum_required(VERSION 3.31)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

# Before project(): decides between a prebuilt Qt kit and vcpkg-built Qt, which
# must be settled before the vcpkg toolchain runs the manifest install.
include(cmake/qt-source.cmake)

project(awen)

# The cross toolchains (emscripten, android NDK) reroot find_package under
# CMAKE_FIND_ROOT_PATH, hiding a prebuilt Qt kit that lives outside their
# sysroots. The toolchain runs during project(), so append after it.
if(AWEN_QT_PREBUILT_DIR)
    list(APPEND CMAKE_FIND_ROOT_PATH "${AWEN_QT_PREBUILT_DIR}")

    # Wasm target finalization calls _qt_test_emscripten_version, defined by
    # the kit's qt.toolchain.cmake — which this build replaces with the
    # emscripten toolchain via vcpkg. Pull in just those definitions; the check
    # then passes because .emscripten-version matches the kit's recommended
    # emcc release.
    if(EMSCRIPTEN)
        include("${AWEN_QT_PREBUILT_DIR}/lib/cmake/Qt6/QtPublicWasmToolchainHelpers.cmake")
    endif()
endif()

# The Windows resource compiler for the icon .rc files awen_add_executable
# generates; enable_language is file-scope-only, so it lives here. WIN32 is off
# for the android/wasm cross builds, which have no rc.
if(WIN32)
    enable_language(RC)
endif()

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
include(cmake/target/clang-format.cmake)
include(cmake/target/clang-tidy.cmake)

find_package(Qt6 6.11 CONFIG REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.11)

# Collect every qt_add_qml_module output under a single tree so that all
# in-project QML modules (e.g. awen.entity) are discoverable via a single
# import path. This is what the auto-generated .qmlls.ini files (and any
# downstream tooling, such as qmllint or deploy scripts) will reference.
#
# That tree is the executables' own directory (where qt_standard_project_setup
# puts them) because the QML engine always imports from the application
# directory: it is what lets an app run from the build tree find the in-project
# modules, while qt.conf points the engine at Qt's own modules. See
# cmake/qt-build-tree-conf.cmake.
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}" CACHE PATH
    "Base output directory for all qt_add_qml_module targets" FORCE)

# Auto-generate .qmlls.ini next to each QML source directory so the QML
# language server picks up the correct per-build import paths regardless of
# platform or preset. See: https://doc.qt.io/qt-6/qtqml-tooling-qmlls.html
set(QT_QML_GENERATE_QMLLS_INI ON CACHE BOOL "Generate .qmlls.ini for qmlls" FORCE)

include(cmake/qt-build-tree-conf.cmake)

# awen_add_qml_module / awen_add_executable, the shared target patterns for
# src/ and app/.
include(cmake/awen-target.cmake)

add_subdirectory(src)
add_subdirectory(app)

# After the subdirectories so targets have registered themselves in the
# PROJECT_COVERAGE_TARGETS global property this script reads.
include(cmake/target/llvm-coverage.cmake)
