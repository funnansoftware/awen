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

if(EMSCRIPTEN)
    # QLibraryInfo probes ":/qt/etc/qt.conf" before main(). Providing it with an
    # explicit Prefix makes QLibraryInfoPrivate::paths() take the fromConf branch
    # and skip getRelocatablePrefix(), whose debug-only Q_ASSERT_X ("Failed to find
    # the Qt prefix path") aborts this static wasm build at QGuiApplication
    # construction: wasm is a static Qt link, so the QT_STATIC branch runs instead
    # of the (dead) Q_OS_WASM branch and prefixFromAppDirHelper() returns empty
    # (no app directory in the browser). Release tolerates it (Q_ASSERT_X is a
    # no-op there), debug does not. Qt's own wasmdeployqt emits an equivalent
    # qt.conf. wasm-only: on desktop a forced Prefix=/ would override the real
    # install prefix and break plugin/QML resolution (see cmake/qt-build-tree-conf.cmake).
    # The explicit alias is required because the file lives outside this directory;
    # PREFIX + alias land it at exactly :/qt/etc/qt.conf.
    set_source_files_properties(
        "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
        PROPERTIES QT_RESOURCE_ALIAS qt.conf
    )
    qt_add_resources(briarthorn briarthorn_wasm_qt_conf
        PREFIX "/qt/etc"
        FILES "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
    )

    # Qt links the app to .js + .wasm and generates the page that loads them, so
    # there is nothing to deploy — Qt is linked in, not shipped alongside. Ship
    # the bundle instead, so the install directory can be served as-is.
    install(FILES
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.html"
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.js"
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.wasm"
        DESTINATION web
    )

    # Emitted only for some configurations (the loader moved into the generated
    # page in newer Qt; the worker only exists in threaded builds), so these are
    # optional rather than predicted exactly.
    install(FILES
        "$<TARGET_FILE_DIR:briarthorn>/qtloader.js"
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.worker.js"
        DESTINATION web
        OPTIONAL
    )

    return()
endif()

if(ANDROID)
    # qt_add_executable built briarthorn as a MODULE library
    # (libbriarthorn_arm64-v8a.so); Qt's finalization generates the deployment
    # settings and the apk targets (apk_all is part of ALL, so a plain build
    # assembles the APK via androiddeployqt + gradle in the build tree). The
    # package identity and the launcher assets under android/ ride the target
    # properties; androiddeployqt overlays android/ onto Qt's package template.
    set_target_properties(briarthorn PROPERTIES
        QT_ANDROID_PACKAGE_NAME "com.funnansoftware.briarthorn"
        QT_ANDROID_VERSION_CODE 1
        QT_ANDROID_VERSION_NAME "1.0"
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    )

    # Ship the assembled APK the way the wasm bundle ships, so the install
    # directory is the artifact.
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/android-build/briarthorn.apk"
        DESTINATION android
    )

    return()
endif()

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
