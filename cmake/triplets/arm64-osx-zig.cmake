# Zig overlay triplet: same settings as the built-in arm64-osx, but ports are
# built with zig via the chainloaded toolchain. Named "-zig" so the arm64-macos
# CMake preset keeps building its dependencies with the system clang.
set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_ENV_PASSTHROUGH PATH)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES arm64)

get_filename_component(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/../toolchain/zig-osx.cmake" ABSOLUTE)
