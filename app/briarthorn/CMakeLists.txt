# Briarthorn — the game, built in QML on the awen framework; own license, see
# LICENSE.md. A thin Qt bootstrap (main.cpp) loads the QML module below.
qt_add_executable(briarthorn)

target_sources(briarthorn
    PRIVATE
        main.cpp
)

# IMPORTS tells the import scan (qmllint, deploy) that Main.qml depends on
# awen.gamepad; the types themselves come from linking awen-gamepad below.
qt_add_qml_module(briarthorn
    URI Briarthorn
    VERSION 1.0
    QML_FILES
        qml/Main.qml
    IMPORTS
        awen.gamepad
)

# No QT_QML_DEBUG: the QML debug server bypasses the compiled units and demands
# the optional qtquick2plugin the deploy step does not ship, failing startup.

target_link_libraries(briarthorn
    PRIVATE
        awen-gamepad
        Qt6::Quick
)

# Windows: embed the application icon into the .exe.
if(WIN32)
    enable_language(RC)
    target_sources(briarthorn PRIVATE briarthorn.rc)
endif()

# qmlcachegen-generated code trips MSVC C4702 (unreachable return) inside Qt
# headers, which /WX would turn into an error — disable just that warning.
if(MSVC)
    target_compile_options(briarthorn PRIVATE /wd4702)
endif()

# macOS needs an .app bundle for macdeployqt; a plain executable fails to launch
# after install.
set_target_properties(briarthorn PROPERTIES
    MACOSX_BUNDLE TRUE
)

if(EMSCRIPTEN)
    # Embed ":/qt/etc/qt.conf" so QLibraryInfo skips getRelocatablePrefix(), whose
    # debug-only assert aborts this static wasm build at startup. wasm-only: on
    # desktop a forced Prefix would break plugin/QML resolution.
    set_source_files_properties(
        "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
        PROPERTIES QT_RESOURCE_ALIAS qt.conf
    )
    qt_add_resources(briarthorn briarthorn_wasm_qt_conf
        PREFIX "/qt/etc"
        FILES "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
    )

    # Qt is linked into the .js/.wasm, so ship the generated bundle; the install
    # directory can then be served as-is.
    install(FILES
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.html"
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.js"
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.wasm"
        DESTINATION web
    )

    # Only emitted for some configurations, so optional rather than predicted.
    install(FILES
        "$<TARGET_FILE_DIR:briarthorn>/qtloader.js"
        "$<TARGET_FILE_DIR:briarthorn>/briarthorn.worker.js"
        DESTINATION web
        OPTIONAL
    )

    # The briarthorn.game entry page, embedding the app in a bounded view; Qt's
    # generated briarthorn.html stays as a debug fallback.
    install(FILES web/index.html DESTINATION web)

    return()
endif()

if(ANDROID)
    # Package identity and launcher assets; androiddeployqt overlays android/ onto
    # Qt's package template and a plain build assembles the APK (apk_all is in ALL).
    set_target_properties(briarthorn PROPERTIES
        QT_ANDROID_PACKAGE_NAME "com.funnansoftware.briarthorn"
        QT_ANDROID_VERSION_CODE 1
        QT_ANDROID_VERSION_NAME "1.0"
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    )

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

# Deploy the Qt libraries, platform plugins and QML imports next to the installed app.
qt_generate_deploy_qml_app_script(
    TARGET briarthorn
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    NO_TRANSLATIONS
)

install(SCRIPT ${deploy_script})

# Headless smoke test: run the real app (minimal platform, software scene graph)
# and quit via the seam in main.cpp — a clean exit proves Main.qml and its
# awen.gamepad import load.
if(BUILD_TESTING)
    add_test(NAME tst_apploads COMMAND briarthorn)
    set_tests_properties(tst_apploads PROPERTIES ENVIRONMENT
        "BRIARTHORN_SMOKE_QUIT_MS=3000;QT_QPA_PLATFORM=minimal;QSG_RHI_BACKEND=software"
    )
    # A build-tree run has no qt.conf pointing at the in-project QML modules (that
    # file is written on Windows only), so Release's loadFromModule needs the
    # import path or it fails with "No module named Briarthorn found".
    set_property(TEST tst_apploads APPEND PROPERTY ENVIRONMENT_MODIFICATION
        "QML_IMPORT_PATH=path_list_append:${QT_QML_OUTPUT_DIRECTORY}"
    )
endif()
