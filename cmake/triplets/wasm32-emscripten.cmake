# Overlay of vcpkg's community wasm32-emscripten triplet (EMSDK detection copied
# verbatim), plus release-only dependencies — the emscripten ABI has no
# debug/release split, and debug Qt wasm was ~380 MB.
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
    # SDL is only used for gamepad input (joystick + events); turn the other
    # subsystems off so wasm-ld does not retain code the game can never run.
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
