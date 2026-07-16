# Overlay shadowing vcpkg's built-in arm64-osx triplet: identical, except Qt
# ports build as shared libraries. Qt is designed to be deployed dynamically
# (plugins, QML modules, the meta-object system, LGPL relinking) and is
# awkward/limited when static; everything else stays static as before.
set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT MATCHES "^qt")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

set(VCPKG_CMAKE_SYSTEM_NAME Darwin)
set(VCPKG_OSX_ARCHITECTURES arm64)

# Dependencies build in release only — same reasoning as x64-linux.cmake: this
# ABI has no debug/release split, so debug apps link release libraries fine.
set(VCPKG_BUILD_TYPE release)
