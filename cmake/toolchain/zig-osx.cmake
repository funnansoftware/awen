# vcpkg chainload toolchain that builds ports with zig targeting native macOS,
# matching the application toolchain (zig build's macos target).
#
# zig cc locates the macOS SDK itself (via xcrun) and tolerates the Apple driver
# flags CMake injects for a Darwin target (-arch, -isysroot, -mmacosx-version-min),
# so unlike zig-linux.cmake we do not reimplement the platform setup: we only
# swap in the zig wrappers and then include vcpkg's stock macOS toolchain for the
# CMAKE_OSX_* architecture/sysroot/rpath and -fPIC handling. It never sets a
# compiler, so the wrappers below win.
#
# Native only: cross-arch (e.g. x64 ports on an arm64 host) is unsupported here
# because `zig cc -arch x86_64` keeps the host's -mcpu; build on a matching arch.
get_filename_component(_zig_compiler_dir "${CMAKE_CURRENT_LIST_DIR}/../../scripts" ABSOLUTE)

# The wrappers come in pairs; pick by the machine running the build.
if(CMAKE_HOST_WIN32)
    set(_zig_ext ".bat")
else()
    set(_zig_ext ".sh")
endif()

set(CMAKE_C_COMPILER   "${_zig_compiler_dir}/zigcc${_zig_ext}")
set(CMAKE_CXX_COMPILER "${_zig_compiler_dir}/zig++${_zig_ext}")
set(CMAKE_AR      "${_zig_compiler_dir}/zigar${_zig_ext}"     CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB  "${_zig_compiler_dir}/zigranlib${_zig_ext}" CACHE FILEPATH "" FORCE)

get_filename_component(_vcpkg_osx_toolchain
    "${CMAKE_CURRENT_LIST_DIR}/../../vcpkg/scripts/toolchains/osx.cmake" ABSOLUTE)
include("${_vcpkg_osx_toolchain}")

# zig cc enables UBSan in trap mode by default; ports are third-party code we
# don't sanitize (see zig-linux.cmake). Appended after the stock toolchain so it
# survives its *_FLAGS_INIT assignments.
string(APPEND CMAKE_C_FLAGS_INIT   " -fno-sanitize=undefined")
string(APPEND CMAKE_CXX_FLAGS_INIT " -fno-sanitize=undefined")
