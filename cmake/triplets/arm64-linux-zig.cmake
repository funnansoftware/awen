# Zig overlay triplet: same settings as the built-in arm64-linux, but ports are
# built with zig via the chainloaded toolchain (shared with x64-linux-zig; the
# arch is read from VCPKG_TARGET_ARCHITECTURE). Named "-zig" so the stock
# arm64-linux triplet stays available to non-zig consumers.
set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_ENV_PASSTHROUGH PATH)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)

get_filename_component(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/../toolchain/zig-linux.cmake" ABSOLUTE)
