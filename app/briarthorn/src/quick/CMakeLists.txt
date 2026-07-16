# The Qt Quick graphics edge AND the app composed around it. Qt owns the event
# loop and the QML module machinery works on the final target, so this directory
# defines the briarthorn executable itself: the app sources plus the Qt shell. Qt
# itself is located by the top-level CMakeLists (find_package +
# qt_standard_project_setup).
qt_add_executable(briarthorn
    ../Briarthorn.cpp
    ../main.cpp
    Application.cpp
)

# The QML module: Main.qml (the window shell) plus the C++ types it instantiates
# — SOURCES here (not target_sources) so the module's qmltyperegistrar/moc pass
# registers them into briarthorn.quick.
qt_add_qml_module(briarthorn
    URI briarthorn.quick
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    SOURCES
        GameController.cpp
        GameController.hpp
        WorldView.cpp
        WorldView.hpp
)

target_link_libraries(briarthorn
    PRIVATE
        briarthorn-game
        Qt6::Quick
)

# Windows: embed the application icon into the .exe via a resource script, so
# Explorer, the taskbar, and Alt-Tab show it.
if(WIN32)
    enable_language(RC)
    target_sources(briarthorn PRIVATE ../briarthorn.rc)
endif()

# qmlcachegen compiles each .qml into C++; some property accesses instantiate Qt
# header templates whose `if constexpr` chains leave a statically unreachable
# `return`. MSVC reports that as C4702 against the Qt header and /WX would turn
# it into a build error — disable just that warning here.
if(MSVC)
    target_compile_options(briarthorn PRIVATE /wd4702)
endif()

# On macOS the app must be an .app bundle for macdeployqt (invoked by the deploy
# script below) to copy Qt's frameworks/plugins into it; a plain executable gets
# no LC_RPATH on install and fails to launch.
set_target_properties(briarthorn PROPERTIES
    MACOSX_BUNDLE TRUE
)

install(TARGETS briarthorn
    BUNDLE DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

# Deploy the dynamic Qt libraries, platform plugins and QML imports next to the
# installed app (macdeployqt/windeployqt/linux rpath handling, driven by Qt).
qt_generate_deploy_qml_app_script(
    TARGET briarthorn
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    NO_TRANSLATIONS
)

install(SCRIPT ${deploy_script})
