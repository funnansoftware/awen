# The framework sample app: the AwenApp QML module behind its own main.cpp.
# On android it packages under Qt's default template identity.
awen_add_executable(awen
    URI AwenApp
    VERSION 1.0
    MAIN main.cpp
    QML_FILES
        Main.qml
        StressScope.qml
    AWEN_MODULES
        entity
        shapes
)

# qmlpreview live-reload: a desktop debug build loads Main.qml from the source
# tree instead of the compiled module, because the engine only reloads QML that
# came from a file URL. The cross builds have no source tree on the device and
# stay on the module path.
if(NOT EMSCRIPTEN AND NOT ANDROID)
    target_compile_definitions(awen PRIVATE
        # QT_QML_DEBUG instantiates QQmlDebuggingEnabler in main.cpp's translation
        # unit, opening the debug connection when the app is started with
        # -qmljsdebugger=... — which is how qmlpreview launches it. Debug only:
        # with the debug server on, the engine wants QML imports the deploy step
        # does not ship.
        $<$<CONFIG:Debug>:QT_QML_DEBUG>
        # Absolute path to the QML sources for main.cpp's file load. Forward
        # slashes from CMake are fine for QUrl::fromLocalFile.
        $<$<CONFIG:Debug>:AWENAPP_QML_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}">
    )
endif()
