# Creates an `llvm-coverage` target that turns llvm source-based coverage data
# into reports: a terminal summary, HTML in <build-dir>/coverage/html, and lcov
# in <build-dir>/coverage/coverage.info.
#
# Contract:
#   * Configure with ENABLE_COVERAGE=ON (the *-coverage presets do this) so
#     project code is compiled with -fprofile-instr-generate -fcoverage-mapping.
#   * Executables to report on register themselves in the
#     PROJECT_COVERAGE_TARGETS global property; this file must be included
#     after the subdirectories that register them.
#   * Test runs write raw profiles into <build-dir>/coverage/*.profraw
#     (gtest_discover_tests sets LLVM_PROFILE_FILE accordingly).
#
# Usage:
#   cmake --preset <preset>-coverage
#   cmake --build --preset <preset>-coverage
#   ctest --preset <preset>-coverage
#   cmake --build --preset <preset>-coverage --target llvm-coverage

if(NOT ENABLE_COVERAGE)
    return()
endif()

# The coverage tools must be able to read the profiles the configured compiler
# produces, so look next to the compiler first, then in the active Xcode
# toolchain (AppleClang keeps them off PATH), then fall back to PATH.
get_filename_component(LLVM_TOOL_HINT_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
set(LLVM_TOOL_HINTS "${LLVM_TOOL_HINT_DIR}")

if(APPLE)
    execute_process(
        COMMAND xcrun --find llvm-profdata
        OUTPUT_VARIABLE XCRUN_LLVM_PROFDATA
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
        RESULT_VARIABLE XCRUN_RESULT
    )

    if(XCRUN_RESULT EQUAL 0)
        get_filename_component(XCRUN_TOOL_DIR "${XCRUN_LLVM_PROFDATA}" DIRECTORY)
        list(APPEND LLVM_TOOL_HINTS "${XCRUN_TOOL_DIR}")
    endif()
endif()

find_program(LLVM_PROFDATA llvm-profdata HINTS ${LLVM_TOOL_HINTS})
find_program(LLVM_COV llvm-cov HINTS ${LLVM_TOOL_HINTS})

if(NOT LLVM_PROFDATA OR NOT LLVM_COV)
    message(WARNING "llvm-profdata and llvm-cov executable(s) not found - llvm-coverage target will be skipped.")
    return()
endif()

get_property(COVERAGE_TARGETS GLOBAL PROPERTY PROJECT_COVERAGE_TARGETS)

if(NOT COVERAGE_TARGETS)
    message(WARNING "no targets registered in PROJECT_COVERAGE_TARGETS - llvm-coverage target will be skipped.")
    return()
endif()

set(COVERAGE_DIR "${CMAKE_BINARY_DIR}/coverage")
file(MAKE_DIRECTORY "${COVERAGE_DIR}")

set(COVERAGE_OBJECT_FILES "")

foreach(COVERAGE_TARGET IN LISTS COVERAGE_TARGETS)
    list(APPEND COVERAGE_OBJECT_FILES "$<TARGET_FILE:${COVERAGE_TARGET}>")
endforeach()

add_custom_target(llvm-coverage
    COMMAND "${CMAKE_COMMAND}"
        "-DLLVM_PROFDATA=${LLVM_PROFDATA}"
        "-DLLVM_COV=${LLVM_COV}"
        "-DCOVERAGE_DIR=${COVERAGE_DIR}"
        "-DOBJECTS=$<JOIN:${COVERAGE_OBJECT_FILES},|>"
        -P "${CMAKE_CURRENT_LIST_DIR}/llvm-coverage-run.cmake"
    COMMENT "Generating llvm coverage reports in ${COVERAGE_DIR}"
    USES_TERMINAL
    VERBATIM
)

add_dependencies(llvm-coverage ${COVERAGE_TARGETS})
