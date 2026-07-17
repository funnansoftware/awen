# awen.gamepad — gamepad input for QML as an attached property (like Keys), backed
# by SDL3 on desktop and wasm. Holds the C++ type QML cannot reach on its own.
#
# Layered like the deleted briarthorn game core so coverage stays clean: the pure,
# renderer-free translation (awen-gamepad-core, Qt-free, unit-tested) is split from
# the SDL/QML edge (this module) — the test links only the core, so its coverage
# report is the translation logic, not untestable SDL/QML glue.
#
# Built SHARED (except on wasm): an app that imports this module resolves it in a
# Release build through loadFromModule against the on-disk qmldir, which loads the
# module's plugin. A static module has no loadable plugin there and its in-process
# registration is dropped by the linker, so `import awen.gamepad` fails at startup
# (Debug loads Main.qml from source and never hits this path). A shared module ships
# the plugin the engine loads — matching the desktop default. On emscripten the whole
# app is one static binary and Qt imports the plugin itself, so static is correct.
set(_awen_gamepad_linkage "")
if(NOT EMSCRIPTEN)
    set(_awen_gamepad_linkage "SHARED")
endif()

qt_add_qml_module(awen-gamepad
    ${_awen_gamepad_linkage}
    URI awen.gamepad
    VERSION 1.0
    QML_FILES
    SOURCES
        # The QML type registers by living under SOURCES (moc + qmltyperegistrar).
        # The backend implementation is added per-platform below.
        Gamepad.h
        Gamepad.cpp
)

target_link_libraries(awen-gamepad
    PUBLIC
        Qt6::Core
        Qt6::Quick
)

if(ANDROID)
    # No SDL activity under androiddeployqt: build an inert backend. The type and
    # enums still register, so `import awen.gamepad` resolves; it just never emits.
    target_sources(awen-gamepad PRIVATE GamepadStub.cpp)
else()
    # Desktop and wasm: SDL3 drives the real input — natively on desktop, and on
    # emscripten through SDL's browser Gamepad API joystick backend, which emits
    # the same SDL_EVENT_GAMEPAD_* stream (d-pad as hat, analog triggers as
    # trigger axes), so GamepadSource.cpp is shared unchanged. sdl3 is excluded
    # only on android in vcpkg.json, so find_package only runs here.
    find_package(SDL3 CONFIG REQUIRED)

    # The tested, Qt-free, renderer-free core. It only reads SDL header structs and
    # constants (no SDL calls), so it needs SDL headers, not the runtime; linking
    # SDL3::SDL3 carries them. Its build dir is the module dir, so the test (in
    # test/) and the SDL backend both resolve GamepadTranslate.h.
    add_library(awen-gamepad-core STATIC
        GamepadTranslate.h
        GamepadTranslate.cpp
    )
    target_include_directories(awen-gamepad-core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(awen-gamepad-core PUBLIC SDL3::SDL3)

    # The SDL backend is selected by compiling GamepadSource.cpp (android compiles
    # GamepadStub.cpp instead) — the backend is chosen by which .cpp builds, so no
    # compile define is needed.
    target_sources(awen-gamepad PRIVATE GamepadSource.cpp)
    target_link_libraries(awen-gamepad
        PRIVATE
            awen-gamepad-core
            SDL3::SDL3
    )

    # The tests run natively (GoogleTest, ctest). The web and android target
    # presets set BUILD_TESTING=OFF (no runner in the browser and gtest is not in
    # the wasm dependency set; an android cross-build cannot execute the binary
    # gtest_discover_tests runs), so this gate holds on desktop only — even
    # though the SDL backend itself now builds for wasm too.
    if(BUILD_TESTING)
        add_subdirectory(test)
    endif()
endif()
