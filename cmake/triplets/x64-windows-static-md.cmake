# Overlay shadowing vcpkg's built-in x64-windows-static-md triplet: identical,
# except Qt ports build as DLLs. Qt is designed to be deployed dynamically
# (plugins, QML modules, the meta-object system, LGPL relinking) and is
# awkward/limited when static; everything else stays static as before. The CRT
# is dynamic either way, so static ports and the Qt DLLs share one runtime.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT MATCHES "^qt")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()
