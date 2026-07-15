# Overlay shadowing vcpkg's built-in x64-linux triplet: identical, except Qt
# ports build as shared libraries. Qt is designed to be deployed dynamically
# (plugins, QML modules, the meta-object system, LGPL relinking) and is
# awkward/limited when static; everything else stays static as before.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT MATCHES "^qt")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
