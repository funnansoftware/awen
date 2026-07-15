# Zig overlay triplet: same settings as the built-in x64-osx, but ports are
# built with zig via the chainloaded toolchain. Named "-zig" so the stock
# x64-osx triplet stays available to non-zig consumers.
#
# Native only: building x64 ports on an arm64 host is unsupported (see
# zig-osx.cmake); build x64-osx-zig on an Intel mac.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
set(VCPKG_ENV_PASSTHROUGH PATH)

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES x86_64)

get_filename_component(VCPKG_CHAINLOAD_TOOLCHAIN_FILE
    "${CMAKE_CURRENT_LIST_DIR}/../toolchain/zig-osx.cmake" ABSOLUTE)
