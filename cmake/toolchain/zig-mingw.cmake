# vcpkg chainload toolchain that builds ports with zig targeting the
# x86_64-windows-gnu (MinGW) ABI, matching the application toolchain.
set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

get_filename_component(_zig_compiler_dir "${CMAKE_CURRENT_LIST_DIR}/../../scripts" ABSOLUTE)

# The wrappers come in pairs; pick by the machine running the build so the
# windows ports can also be cross-built from a linux host.
if(CMAKE_HOST_WIN32)
    set(_zig_ext ".bat")
else()
    set(_zig_ext ".sh")
endif()

set(CMAKE_C_COMPILER   "${_zig_compiler_dir}/zigcc${_zig_ext}")
set(CMAKE_CXX_COMPILER "${_zig_compiler_dir}/zig++${_zig_ext}")
set(CMAKE_C_COMPILER_TARGET   x86_64-windows-gnu)
set(CMAKE_CXX_COMPILER_TARGET x86_64-windows-gnu)

set(CMAKE_AR      "${_zig_compiler_dir}/zigar${_zig_ext}"     CACHE FILEPATH "" FORCE)
set(CMAKE_RANLIB  "${_zig_compiler_dir}/zigranlib${_zig_ext}" CACHE FILEPATH "" FORCE)

# zig cc enables UBSan in trap mode by default; ports are third-party code we
# don't sanitize (see zig-linux.cmake).
string(APPEND CMAKE_C_FLAGS_INIT   " -fno-sanitize=undefined")
string(APPEND CMAKE_CXX_FLAGS_INIT " -fno-sanitize=undefined")
