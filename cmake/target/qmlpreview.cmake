# Per-app "run under qmlpreview" targets. qmlpreview starts the app with Qt's
# QML debug connection open and pushes edited QML files into it, so a running
# app picks up QML edits with no rebuild.
#
# Unlike the Qt build tools (qmlcachegen, moc, ...) qmlpreview is not exported
# as an imported target, so it has to be found on disk: a prebuilt kit keeps it
# in bin/, while vcpkg relocates the Qt tools to tools/Qt6/bin. Include after
# find_package(Qt6), which is what defines QT6_INSTALL_PREFIX.
find_program(QMLPREVIEW_EXECUTABLE
    NAMES qmlpreview
    HINTS
        "${QT6_INSTALL_PREFIX}/${QT6_INSTALL_BINS}"
        "${QT6_INSTALL_PREFIX}/tools/Qt6/bin"
    DOC "Qt's QML preview tool, which live-reloads QML into a running app"
)

if(NOT QMLPREVIEW_EXECUTABLE)
    message(STATUS "qmlpreview executable not found - the <app>-qmlpreview targets will be skipped.")
endif()

# Adds <target>-qmlpreview: build the app, then run it under qmlpreview. Live
# reload wants a Debug build, which is where the apps define QT_QML_DEBUG (no
# debug connection without it) and load Main.qml from the source tree (the
# engine only reloads QML that came from a file URL).
function(awen_add_qmlpreview_target target)
    if(NOT QMLPREVIEW_EXECUTABLE)
        return()
    endif()

    # Without QT_QML_DEBUG the app has no debug connection, so it starts,
    # silently ignores the -qmljsdebugger argument qmlpreview passes it, and no
    # edit ever arrives. The run is harmless, so warn and go ahead.
    set(warning "")
    if(NOT CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(warning COMMAND ${CMAKE_COMMAND} -E echo
            "warning: not a Debug build - QT_QML_DEBUG is Debug-only, so QML edits will not reload")
    endif()

    # USES_TERMINAL so the app's output streams to the terminal as it runs
    # instead of arriving buffered at exit, and Ctrl+C reaches the app.
    add_custom_target(${target}-qmlpreview
        ${warning}
        COMMAND ${QMLPREVIEW_EXECUTABLE} $<TARGET_FILE:${target}>
        USES_TERMINAL
        COMMENT "Running ${target} under qmlpreview - edit its QML to reload it"
        VERBATIM
    )

    add_dependencies(${target}-qmlpreview ${target})
endfunction()
