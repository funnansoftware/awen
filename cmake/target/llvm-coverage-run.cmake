# cmake -P script invoked by the llvm-coverage custom target.
# Merges the raw profiles in COVERAGE_DIR and emits a terminal summary, an HTML
# report, and an lcov export. LLVM_PROFDATA, LLVM_COV, COVERAGE_DIR, and
# OBJECTS ('|'-separated binary paths) are passed via -D on the command line.

file(GLOB PROFRAW_FILES "${COVERAGE_DIR}/*.profraw")

if(NOT PROFRAW_FILES)
    message(FATAL_ERROR
        "no .profraw files in ${COVERAGE_DIR} - configure with ENABLE_COVERAGE=ON and run the tests (ctest) first.")
endif()

string(REPLACE "|" ";" OBJECT_FILES "${OBJECTS}")

set(OBJECT_ARGS "")

foreach(OBJECT_FILE IN LISTS OBJECT_FILES)
    list(APPEND OBJECT_ARGS -object "${OBJECT_FILE}")
endforeach()

# Keep first-party non-test code in the reports.
set(IGNORE_REGEX "vcpkg_installed|[/\\\\]test[/\\\\]")

set(MERGED_PROFDATA "${COVERAGE_DIR}/merged.profdata")

execute_process(
    COMMAND "${LLVM_PROFDATA}" merge -sparse ${PROFRAW_FILES} -o "${MERGED_PROFDATA}"
    RESULT_VARIABLE MERGE_RESULT
)

if(NOT MERGE_RESULT EQUAL 0)
    message(FATAL_ERROR "llvm-profdata merge failed (exit code ${MERGE_RESULT})")
endif()

execute_process(
    COMMAND "${LLVM_COV}" report ${OBJECT_ARGS}
        -instr-profile=${MERGED_PROFDATA}
        -ignore-filename-regex=${IGNORE_REGEX}
    RESULT_VARIABLE REPORT_RESULT
)

if(NOT REPORT_RESULT EQUAL 0)
    message(FATAL_ERROR "llvm-cov report failed (exit code ${REPORT_RESULT})")
endif()

execute_process(
    COMMAND "${LLVM_COV}" show ${OBJECT_ARGS}
        -format=html
        -output-dir=${COVERAGE_DIR}/html
        -instr-profile=${MERGED_PROFDATA}
        -ignore-filename-regex=${IGNORE_REGEX}
    RESULT_VARIABLE SHOW_RESULT
)

if(NOT SHOW_RESULT EQUAL 0)
    message(FATAL_ERROR "llvm-cov show failed (exit code ${SHOW_RESULT})")
endif()

execute_process(
    COMMAND "${LLVM_COV}" export ${OBJECT_ARGS}
        -format=lcov
        -instr-profile=${MERGED_PROFDATA}
        -ignore-filename-regex=${IGNORE_REGEX}
    OUTPUT_FILE "${COVERAGE_DIR}/coverage.info"
    RESULT_VARIABLE EXPORT_RESULT
)

if(NOT EXPORT_RESULT EQUAL 0)
    message(FATAL_ERROR "llvm-cov export failed (exit code ${EXPORT_RESULT})")
endif()

message(STATUS "coverage reports written to ${COVERAGE_DIR} (html/, coverage.info)")
