# Layers, bottom-up: the game core (renderer-free simulation + state), then one
# graphics edge. The qt manifest feature — set by the desktop CMake presets —
# selects the Qt Quick renderer; without it (the zig build, android, emscripten)
# the raylib edge below renders as before.
add_subdirectory(game)

if("qt" IN_LIST VCPKG_MANIFEST_FEATURES)
    add_subdirectory(quick) # defines the briarthorn executable around Qt Quick
    return()
endif()

add_subdirectory(raylib)

if(ANDROID)
    # Android's NativeActivity loads the app as a shared library.
    add_library(briarthorn SHARED)
else()
    add_executable(briarthorn)
endif()

# The app: the Briarthorn owning object plus the entry point.
target_sources(briarthorn
    PRIVATE
        Briarthorn.cpp
        main.cpp
)

# Briarthorn depends only on the game core; main.cpp attaches the raylib graphics
# surface, so the app links both.
target_link_libraries(briarthorn
    PRIVATE
        briarthorn-game
        briarthorn-raylib
)

# Windows: embed the application icon into the .exe via a resource script, so
# Explorer, the taskbar, and Alt-Tab show it. Skip the Zig/MinGW (windows-gnu)
# toolchain — no RC compiler is configured for it here, and the native
# `zig build` path embeds the icon itself (addWin32ResourceFile in
# src/build.zig). MSVC / clang-cl compile briarthorn.rc with rc.exe and link the
# resulting .res.
if(WIN32 AND NOT CMAKE_CXX_COMPILER_TARGET MATCHES "windows-gnu")
    enable_language(RC)
    target_sources(briarthorn PRIVATE briarthorn.rc)
endif()

if(EMSCRIPTEN)
    target_link_options(briarthorn
        PRIVATE
            -sUSE_GLFW=3
            -sASYNCIFY
            # Custom HTML shell that carries the app icon as the browser-tab
            # favicon (SHELL: keeps the flag and its path together through
            # CMake's option de-duplication).
            "SHELL:--shell-file ${CMAKE_CURRENT_SOURCE_DIR}/../web/shell.html"
    )
    # Re-link when the shell changes (link options are not tracked as inputs).
    set_target_properties(briarthorn PROPERTIES
        LINK_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/../web/shell.html")

    set_target_properties(briarthorn PROPERTIES SUFFIX ".html")

    install(FILES
        ${CMAKE_CURRENT_BINARY_DIR}/briarthorn.html
        ${CMAKE_CURRENT_BINARY_DIR}/briarthorn.js
        ${CMAKE_CURRENT_BINARY_DIR}/briarthorn.wasm
        DESTINATION web
    )
elseif(ANDROID)
    find_library(log-lib log)
    find_library(android-lib android)
    find_library(GLESv2-lib GLESv2)
    find_library(EGL-lib EGL)
    find_library(OpenSLES-lib OpenSLES)

    target_link_libraries(briarthorn
        PRIVATE
            ${log-lib}
            ${android-lib}
            ${GLESv2-lib}
            ${EGL-lib}
            ${OpenSLES-lib}
            atomic
    )

    # Force-export ANativeActivity_onCreate from raylib's static lib so that
    # Android's NativeActivity can find the entry point in the shared library.
    target_link_options(briarthorn
        PRIVATE
            -u ANativeActivity_onCreate
    )
endif()

if(NOT EMSCRIPTEN)
    install(TARGETS briarthorn
        BUNDLE DESTINATION .
        RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
        LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    )
endif()
