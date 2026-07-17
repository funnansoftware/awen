# Overlay shadowing vcpkg's built-in (community) wasm32-emscripten triplet:
# identical — the EMSDK detection and toolchain chainload below are copied
# verbatim, and every port build depends on them — plus release-only
# dependencies at the end. Everything is static on wasm and the emscripten ABI
# has no debug/release split, so both web presets link these release
# libraries; debug Qt for wasm only doubled the build time and produced
# ~380 MB debug .wasm binaries.
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED EMSCRIPTEN_ROOT EMSDK PATH)

if(NOT DEFINED ENV{EMSCRIPTEN_ROOT})
   find_path(EMSCRIPTEN_ROOT "emcc")
else()
   set(EMSCRIPTEN_ROOT "$ENV{EMSCRIPTEN_ROOT}")
endif()

if(NOT EMSCRIPTEN_ROOT)
   if(NOT DEFINED ENV{EMSDK})
      message(FATAL_ERROR "The emcc compiler not found in PATH")
   endif()
   set(EMSCRIPTEN_ROOT "$ENV{EMSDK}/upstream/emscripten")
endif()

if(NOT EXISTS "${EMSCRIPTEN_ROOT}/cmake/Modules/Platform/Emscripten.cmake")
   message(FATAL_ERROR "Emscripten.cmake toolchain file not found")
endif()

set(VCPKG_TARGET_ARCHITECTURE wasm32)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_CMAKE_SYSTEM_NAME Emscripten)
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "${EMSCRIPTEN_ROOT}/cmake/Modules/Platform/Emscripten.cmake")

set(VCPKG_BUILD_TYPE release)

if(PORT STREQUAL "sdl3")
    # awen uses SDL in the browser only for gamepad input (src/awen/gamepad —
    # SDL_INIT_GAMEPAD pulls just the joystick and events subsystems). SDL's
    # default build still compiles every other subsystem, and because the init
    # dispatch references each one, wasm-ld retains code the game can never run
    # (Qt owns the canvas and audio). Turn those subsystems off so they never
    # enter the shipped .wasm; joystick/events stay on by default. Gamepad
    # rumble is unaffected: on the web it rides the joystick backend
    # (vibrationActuator), not SDL_HAPTIC.
    list(APPEND VCPKG_CMAKE_CONFIGURE_OPTIONS
        -DSDL_AUDIO=OFF
        -DSDL_VIDEO=OFF
        -DSDL_RENDER=OFF
        -DSDL_GPU=OFF
        -DSDL_CAMERA=OFF
        -DSDL_HAPTIC=OFF
        -DSDL_SENSOR=OFF
        -DSDL_POWER=OFF
        -DSDL_DIALOG=OFF
    )
endif()
