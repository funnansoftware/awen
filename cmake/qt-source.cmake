# Decide where Qt comes from — a prebuilt kit (Qt online installer / aqtinstall)
# or vcpkg building it from source — before project() runs the vcpkg manifest
# install. Skipping the Qt ports turns a cold ~50 min dependency build into a
# download, while gtest and SDL3 keep coming from vcpkg either way.
#
# AWEN_QT selects the source (the AWEN_QT environment variable seeds the
# default, so CI can pin it without touching configure commands):
#   auto     — use a prebuilt kit when one is found, else fall back to vcpkg.
#   prebuilt — require a kit; fail the configure when none is found.
#   vcpkg    — always build Qt via vcpkg (the manifest's default "qt" feature).
#
# A kit is looked for in this order: AWEN_QT_ROOT (explicit kit directory),
# the QT_ROOT_DIR environment variable (exported by jurplel/install-qt-action),
# then conventional installer roots (C:/Qt, ~/Qt, /opt/Qt). Conventional roots
# are scanned for <root>/<version>/<kit> with the kit name keyed off
# VCPKG_TARGET_TRIPLET, taking the newest version >= 6.11.
#
# Must be included BEFORE project(): VCPKG_MANIFEST_NO_DEFAULT_FEATURES is read
# by the vcpkg toolchain when project() triggers the manifest install, and for
# the cross targets (wasm, android) QT_HOST_PATH has to exist before find_package.

set(_awen_qt_minimum "6.11")

if(DEFINED ENV{AWEN_QT} AND NOT "$ENV{AWEN_QT}" STREQUAL "")
    set(_awen_qt_default "$ENV{AWEN_QT}")
else()
    set(_awen_qt_default "auto")
endif()

set(AWEN_QT "${_awen_qt_default}" CACHE STRING
    "Where Qt comes from: auto (prebuilt kit when found, else vcpkg), prebuilt, or vcpkg")
set_property(CACHE AWEN_QT PROPERTY STRINGS auto prebuilt vcpkg)
set(AWEN_QT_ROOT "" CACHE PATH
    "Explicit prebuilt Qt kit directory (the one containing lib/cmake/Qt6)")

if(NOT AWEN_QT MATCHES "^(auto|prebuilt|vcpkg)$")
    message(FATAL_ERROR "AWEN_QT is '${AWEN_QT}'; expected auto, prebuilt, or vcpkg.")
endif()

if(NOT AWEN_QT STREQUAL "vcpkg")
    # The kit directory name Qt's installers use for each of this repo's vcpkg
    # target triplets; wasm and android are cross builds needing host tools too.
    set(_awen_qt_cross FALSE)
    if(VCPKG_TARGET_TRIPLET STREQUAL "wasm32-emscripten")
        set(_awen_qt_kit "wasm_singlethread")
        set(_awen_qt_cross TRUE)
    elseif(VCPKG_TARGET_TRIPLET STREQUAL "arm64-android")
        set(_awen_qt_kit "android_arm64_v8a")
        set(_awen_qt_cross TRUE)
    elseif(VCPKG_TARGET_TRIPLET MATCHES "^x64-windows")
        set(_awen_qt_kit "msvc2022_64")
    elseif(VCPKG_TARGET_TRIPLET STREQUAL "x64-linux")
        set(_awen_qt_kit "gcc_64")
    elseif(VCPKG_TARGET_TRIPLET STREQUAL "arm64-osx")
        set(_awen_qt_kit "macos")
    elseif(CMAKE_HOST_WIN32)
        set(_awen_qt_kit "msvc2022_64")
    elseif(CMAKE_HOST_APPLE)
        set(_awen_qt_kit "macos")
    else()
        set(_awen_qt_kit "gcc_64")
    endif()

    # The host kit name for cross builds (moc, qmlcachegen, androiddeployqt run
    # on the build machine).
    if(CMAKE_HOST_WIN32)
        set(_awen_qt_host_kit "msvc2022_64")
    elseif(CMAKE_HOST_APPLE)
        set(_awen_qt_host_kit "macos")
    else()
        set(_awen_qt_host_kit "gcc_64")
    endif()

    set(_awen_qt_prebuilt "")

    # Explicit locations are trusted as-is; find_package still enforces the
    # minimum version.
    foreach(_awen_qt_candidate IN ITEMS "${AWEN_QT_ROOT}" "$ENV{QT_ROOT_DIR}")
        if(NOT _awen_qt_prebuilt AND _awen_qt_candidate
           AND EXISTS "${_awen_qt_candidate}/lib/cmake/Qt6/Qt6Config.cmake")
            set(_awen_qt_prebuilt "${_awen_qt_candidate}")
        endif()
    endforeach()

    # Conventional installer roots: <root>/<version>/<kit>, newest version wins.
    if(NOT _awen_qt_prebuilt)
        set(_awen_qt_roots "")
        if(CMAKE_HOST_WIN32)
            list(APPEND _awen_qt_roots "C:/Qt")
        endif()
        if(DEFINED ENV{HOME})
            list(APPEND _awen_qt_roots "$ENV{HOME}/Qt")
        endif()
        list(APPEND _awen_qt_roots "/opt/Qt")

        set(_awen_qt_best_version "0")
        foreach(_awen_qt_root IN LISTS _awen_qt_roots)
            file(GLOB _awen_qt_versions RELATIVE "${_awen_qt_root}" "${_awen_qt_root}/6.*")
            foreach(_awen_qt_version IN LISTS _awen_qt_versions)
                if(_awen_qt_version VERSION_GREATER_EQUAL _awen_qt_minimum
                   AND _awen_qt_version VERSION_GREATER _awen_qt_best_version
                   AND EXISTS "${_awen_qt_root}/${_awen_qt_version}/${_awen_qt_kit}/lib/cmake/Qt6/Qt6Config.cmake")
                    set(_awen_qt_best_version "${_awen_qt_version}")
                    set(_awen_qt_prebuilt "${_awen_qt_root}/${_awen_qt_version}/${_awen_qt_kit}")
                endif()
            endforeach()
        endforeach()
    endif()

    if(_awen_qt_prebuilt)
        # Skip the manifest's default "qt" feature; gtest and SDL3 are top-level
        # dependencies and still install.
        set(VCPKG_MANIFEST_NO_DEFAULT_FEATURES ON)
        list(PREPEND CMAKE_PREFIX_PATH "${_awen_qt_prebuilt}")
        set(AWEN_QT_PREBUILT_DIR "${_awen_qt_prebuilt}")
        message(STATUS "Qt: prebuilt kit at ${_awen_qt_prebuilt} (vcpkg skips the Qt ports)")

        if(_awen_qt_cross AND NOT QT_HOST_PATH)
            # install-qt-action exports QT_HOST_PATH; a local installer layout
            # keeps the host kit beside the target kit under the same version.
            if(DEFINED ENV{QT_HOST_PATH}
               AND EXISTS "$ENV{QT_HOST_PATH}/lib/cmake/Qt6/Qt6Config.cmake")
                set(QT_HOST_PATH "$ENV{QT_HOST_PATH}" CACHE PATH "Host Qt for cross builds")
            else()
                get_filename_component(_awen_qt_version_dir "${_awen_qt_prebuilt}" DIRECTORY)
                set(_awen_qt_host "${_awen_qt_version_dir}/${_awen_qt_host_kit}")
                if(EXISTS "${_awen_qt_host}/lib/cmake/Qt6/Qt6Config.cmake")
                    set(QT_HOST_PATH "${_awen_qt_host}" CACHE PATH "Host Qt for cross builds")
                else()
                    message(FATAL_ERROR
                        "Prebuilt Qt at ${_awen_qt_prebuilt} is a cross kit but no host kit "
                        "was found (looked at QT_HOST_PATH and ${_awen_qt_host}). Install the "
                        "matching desktop Qt (aqtinstall: --autodesktop) or set QT_HOST_PATH.")
                endif()
            endif()
        endif()
    elseif(AWEN_QT STREQUAL "prebuilt")
        message(FATAL_ERROR
            "AWEN_QT=prebuilt but no Qt kit '>= ${_awen_qt_minimum}' with kit directory "
            "'${_awen_qt_kit}' was found via AWEN_QT_ROOT, the QT_ROOT_DIR environment "
            "variable, or the conventional roots (C:/Qt, ~/Qt, /opt/Qt). Install one with "
            "the Qt online installer or aqtinstall, or configure with AWEN_QT=vcpkg.")
    else()
        message(STATUS "Qt: no prebuilt kit found; vcpkg builds Qt from source")
    endif()
endif()
