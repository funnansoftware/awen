# vcpkg chainload toolchain that builds ports with zig targeting
# <arch>-linux-gnu, matching the application toolchain. The architecture comes
# from the overlay triplet's VCPKG_TARGET_ARCHITECTURE, so one file serves both
# x64-linux-zig and arm64-linux-zig.
#
# Note: ports that need target-platform system headers (e.g. X11 for glfw3)
# still require them to be installed on the build machine; zig replaces the
# compiler, not the platform SDK. Because we stay native (no --target, see
# below), the build machine must match the target architecture.
set(CMAKE_SYSTEM_NAME Linux)
if(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(CMAKE_SYSTEM_PROCESSOR aarch64)
    set(_zig_multiarch aarch64-linux-gnu)
else()
    set(CMAKE_SYSTEM_PROCESSOR x86_64)
    set(_zig_multiarch x86_64-linux-gnu)
endif()

get_filename_component(_zig_compiler_dir "${CMAKE_CURRENT_LIST_DIR}/../../scripts" ABSOLUTE)

# The wrappers come in pairs; pick by the machine running the build.
if(CMAKE_HOST_WIN32)
    set(_zig_ext ".bat")
else()
    set(_zig_ext ".sh")
endif()

set(CMAKE_C_COMPILER   "${_zig_compiler_dir}/zigcc${_zig_ext}")
set(CMAKE_CXX_COMPILER "${_zig_compiler_dir}/zig++${_zig_ext}")
# Do NOT set CMAKE_*_COMPILER_TARGET here: an explicit --target puts zig cc in
# cross-compile mode, so it links its bundled glibc baseline and stops
# searching system library dirs (breaks FindX11 and glibc symbol resolution).
# Leaving it unset means native, which detects the real system glibc.

# zig's verbose link output exposes no implicit -L dirs, so CMake cannot
# infer the Debian/Ubuntu multiarch libdir; without this, find_library never
# looks in /usr/lib/<multiarch> (where libX11 & friends live).
set(CMAKE_LIBRARY_ARCHITECTURE ${_zig_multiarch})

# zig cc enables UBSan in trap mode by default. Ports are third-party code we
# don't sanitize (e.g. raylib's GetCurrentMonitor overflows int on WSLg's huge
# virtual monitor coordinates and would abort at runtime).
string(APPEND CMAKE_C_FLAGS_INIT   " -fno-sanitize=undefined")
string(APPEND CMAKE_CXX_FLAGS_INIT " -fno-sanitize=undefined")

set(CMAKE_AR      "${_zig_compiler_dir}/zigar${_zig_ext}"     CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB  "${_zig_compiler_dir}/zigranlib${_zig_ext}" CACHE FILEPATH "" FORCE)
