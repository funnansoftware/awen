# Overlay shadowing vcpkg's built-in x64-windows-release triplet: the same
# linkage as the x64-windows overlay (static ports, dynamic CRT, Qt as DLLs),
# but dependencies build in release only — a release app never loads a debug
# Qt, so building one just doubles the Qt build time and the binary cache.
# Used by the windows release presets (host and target).
#
# Release-only stays confined to the release presets on windows: an MSVC debug
# binary cannot link these libraries (see x64-windows.cmake).
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT MATCHES "^qt")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

set(VCPKG_BUILD_TYPE release)
