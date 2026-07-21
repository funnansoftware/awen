# Briarthorn — the game, built in QML on the awen framework; own license, see
# LICENSE.md. The shared bootstrap loads the Briarthorn QML module.
awen_add_executable(briarthorn
    URI Briarthorn
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/systems/SystemMovement.qml
    AWEN_MODULES
        entity
        gamepad
        shapes
    WINDOWS_ICON briarthorn.ico
    # The briarthorn.game entry page, embedding the app in a bounded view; Qt's
    # generated briarthorn.html stays as a debug fallback.
    WEB_SHELL web/index.html
)

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
