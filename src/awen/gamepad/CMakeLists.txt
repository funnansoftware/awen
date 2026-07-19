# awen.gamepad — gamepad input for QML as an attached property (like Keys), backed
# by SDL3 on desktop and wasm. The Qt-free awen-gamepad-core below holds the
# unit-tested translation logic; this module is the SDL/QML edge on top of it.

awen_add_qml_module(awen-gamepad
    URI awen.gamepad
    VERSION 1.0
    QML_FILES
    SOURCES
        Gamepad.h
        Gamepad.cpp
)

if(ANDROID)
    # No SDL activity under androiddeployqt: inert backend, but the type and enums
    # still register so `import awen.gamepad` resolves.
    target_sources(awen-gamepad PRIVATE GamepadStub.cpp)
else()
    # SDL3 drives the input — natively on desktop, via SDL's browser Gamepad API
    # backend on emscripten. Same event stream, so GamepadSource.cpp is shared.
    find_package(SDL3 CONFIG REQUIRED)

    # The Qt-free, unit-tested core; it only reads SDL headers (no SDL calls).
    add_library(awen-gamepad-core STATIC
        GamepadTranslate.h
        GamepadTranslate.cpp
    )
    target_include_directories(awen-gamepad-core PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
    target_link_libraries(awen-gamepad-core PUBLIC SDL3::SDL3)

    target_sources(awen-gamepad PRIVATE GamepadSource.cpp)
    target_link_libraries(awen-gamepad
        PRIVATE
            awen-gamepad-core
            SDL3::SDL3
    )

    # Tests run natively only; the web and android presets set BUILD_TESTING=OFF.
    if(BUILD_TESTING)
        add_subdirectory(test)
    endif()
endif()
