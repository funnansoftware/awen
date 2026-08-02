# The QML counterpart to the clang-format / clang-tidy target pairs: `qmllint`
# reports on the project's QML, `qmllint-check` gates on it. Qt's own generated
# all_qmllint runs the same tool but always exits 0, so it can report and never
# fail — the check target passes -W 0 (error on more than zero warnings), which
# is what makes it usable from CI.
#
# Contract:
#   * QML modules register themselves in the PROJECT_QML_TARGETS global
#     property; this file must be included after the subdirectories that
#     register them, because linting resolves the in-project imports out of
#     their generated .qmltypes.
#
# Usage:
#   cmake --build --preset <preset> --target qmllint
#   cmake --build --preset <preset> --target qmllint-check
#
# Like qmlpreview, qmllint is not exported as an imported target, so it has to
# be found on disk: a prebuilt kit keeps it in bin/, vcpkg relocates the Qt
# tools to tools/Qt6/bin, and a cross build (wasm, android) has the host tools
# under QT_HOST_PATH rather than in the target kit. Include after
# find_package(Qt6), which is what defines QT6_INSTALL_PREFIX.
find_program(QMLLINT_EXECUTABLE
    NAMES qmllint
    HINTS
        "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}"
        "${QT6_INSTALL_PREFIX}/tools/Qt6/bin"
        "${QT_HOST_PATH}/bin"
    DOC "Qt's QML syntax verifier and analyzer"
)

if(NOT QMLLINT_EXECUTABLE)
    message(STATUS "qmllint executable not found - the qmllint targets will be skipped.")
    return()
endif()

get_property(QML_TARGETS GLOBAL PROPERTY PROJECT_QML_TARGETS)

file(GLOB_RECURSE QML_LINT_FILES CONFIGURE_DEPENDS
    ${CMAKE_SOURCE_DIR}/app/*.qml
    ${CMAKE_SOURCE_DIR}/src/*.qml
)

# The single import path every in-project module builds into, so qmllint
# resolves `import awen.entity` the same way the running app does.
set(QML_LINT_COMMAND "${QMLLINT_EXECUTABLE}" -I "${QT_QML_OUTPUT_DIRECTORY}")

add_custom_target(qmllint
    COMMAND ${QML_LINT_COMMAND} ${QML_LINT_FILES}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Linting QML files..."
    VERBATIM
)

add_custom_target(qmllint-check
    COMMAND ${QML_LINT_COMMAND} -W 0 ${QML_LINT_FILES}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Checking QML files for lint warnings..."
    VERBATIM
)

# Both read the modules' generated type information, which only exists once the
# modules have been built.
if(QML_TARGETS)
    add_dependencies(qmllint ${QML_TARGETS})
    add_dependencies(qmllint-check ${QML_TARGETS})
endif()
