# Briarthorn — the game, built in QML on the awen framework; own license, see
# LICENSE.md. A thin Qt bootstrap (main.cpp) loads the QML module below.

# IMPORTS tells the import scan (qmllint, deploy) that the QML files depend on
# awen.entity and awen.gamepad; the types come from the linked modules below.
awen_add_executable(briarthorn
    URI Briarthorn
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/systems/SystemMovement.qml
    IMPORTS
        awen.entity
        awen.gamepad
)

target_sources(briarthorn
    PRIVATE
        main.cpp
)

target_link_libraries(briarthorn
    PRIVATE
        awen-entity
        awen-gamepad
)

# Windows: embed the application icon into the .exe. enable_language is
# file-scope-only, so this cannot move into the wrapper.
if(WIN32)
    enable_language(RC)
    target_sources(briarthorn PRIVATE briarthorn.rc)
endif()

if(EMSCRIPTEN)
    # The briarthorn.game entry page, embedding the app in a bounded view; Qt's
    # generated briarthorn.html stays as a debug fallback.
    install(FILES web/index.html DESTINATION web)
endif()

if(ANDROID)
    # Package identity and launcher assets; androiddeployqt overlays android/
    # onto Qt's package template.
    set_target_properties(briarthorn PROPERTIES
        QT_ANDROID_PACKAGE_NAME "com.funnansoftware.briarthorn"
        QT_ANDROID_VERSION_CODE 1
        QT_ANDROID_VERSION_NAME "1.0"
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    )
endif()

# Headless smoke test: run the real app (minimal platform, software scene graph)
# and quit via the seam in main.cpp — a clean exit proves Main.qml and its
# awen.gamepad import load. Native only — a wasm/android binary isn't runnable here.
if(BUILD_TESTING AND NOT EMSCRIPTEN AND NOT ANDROID)
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
