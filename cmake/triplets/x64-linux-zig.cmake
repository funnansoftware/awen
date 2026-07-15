# Zig overlay triplet: same settings as the built-in x64-linux, but ports are
# built with zig via the chainloaded toolchain. Named "-zig" (rather than
# shadowing x64-linux) so the native CMake presets keep using the stock triplet
# and only zig builds opt in.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_ENV_PASSTHROUGH PATH)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)

get_filename_component(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/../toolchain/zig-linux.cmake" ABSOLUTE)
