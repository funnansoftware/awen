# Overlay shadowing vcpkg's built-in x64-windows triplet: dependencies build as
# static libraries against the dynamic CRT, except Qt ports, which build as
# DLLs. Qt is designed to be deployed dynamically (plugins, QML modules, the
# meta-object system, LGPL relinking) and is awkward/limited when static; the
# CRT is dynamic either way, so static ports and the Qt DLLs share one runtime.
#
# This is the dual-config (debug + release) triplet, used by the windows debug
# preset — and, being vcpkg's default host name on a Windows machine, by the
# web presets' host tools. Never add VCPKG_BUILD_TYPE here: MSVC debug binaries
# cannot consume release dependencies (the static ports' objects carry
# /FAILIFMISMATCH records for _ITERATOR_DEBUG_LEVEL and RuntimeLibrary, so the
# link fails with LNK2038; the Qt DLLs would link but leave a two-CRT process).
# The release presets use x64-windows-release instead.
set(VCPKG_TARGET_ARCHITECTURE x64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT MATCHES "^qt")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()
