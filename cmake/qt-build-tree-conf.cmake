# Make the apps runnable from the BUILD tree on Windows, for both Qt sources.
#
# vcpkg: its app-local deployment copies the Qt DLLs next to each executable.
# That defeats Qt's relocatable prefix detection, which derives the install
# prefix from the location of Qt6Core: with the DLL sitting beside the .exe, the
# prefix resolves to the executable's own directory, which holds no plugins or
# QML imports. QGuiApplication then aborts with "no Qt platform plugin could be
# initialized" before main gets anywhere.
#
# Prebuilt kit: nothing copies the Qt DLLs at all, so executables (and the
# smoke test ctest runs) fail to even load from a shell without the kit on
# PATH. Copy the config-matching Qt6 DLLs beside the executables ourselves —
# which then defeats prefix detection exactly as above.
#
# qt.conf is Qt's sanctioned override for both cases: Qt reads it from the
# application directory at startup and takes its paths from there. Point it at
# the real Qt tree. The installed app needs none of this — the deploy script's
# windeployqt writes an equivalent qt.conf of its own.
#
# vcpkg's Qt layout (<prefix>/Qt6/plugins and <prefix>/Qt6/qml, with the debug
# build under the triplet's debug/ subdirectory) differs from Qt's defaults and
# must be spelled out; a prebuilt kit uses the default plugins/ and qml/ names,
# so its Prefix line suffices.
#
# Include after qt_standard_project_setup(), which is what points the runtime
# output directory at the build root.
if(WIN32 AND (DEFINED VCPKG_INSTALLED_DIR OR AWEN_QT_PREBUILT_DIR))
    if(CMAKE_RUNTIME_OUTPUT_DIRECTORY)
        set(_qt_conf_dir "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
    else()
        set(_qt_conf_dir "${CMAKE_BINARY_DIR}")
    endif()

    if(AWEN_QT_PREBUILT_DIR)
        set(_qt_conf_prefix "${AWEN_QT_PREBUILT_DIR}")

        # Debug executables link the d-suffixed DLLs, release the plain ones.
        file(GLOB _qt_kit_dlls "${AWEN_QT_PREBUILT_DIR}/bin/Qt6*.dll")
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            list(FILTER _qt_kit_dlls INCLUDE REGEX "d\\.dll$")
        else()
            list(FILTER _qt_kit_dlls EXCLUDE REGEX "d\\.dll$")
        endif()
        file(COPY ${_qt_kit_dlls} DESTINATION "${_qt_conf_dir}")
        unset(_qt_kit_dlls)

        file(WRITE "${_qt_conf_dir}/qt.conf"
            "[Paths]\n"
            "Prefix = ${_qt_conf_prefix}\n")
    else()
        if(CMAKE_BUILD_TYPE STREQUAL "Debug")
            set(_qt_conf_prefix "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug")
        else()
            set(_qt_conf_prefix "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
        endif()

        file(WRITE "${_qt_conf_dir}/qt.conf"
            "[Paths]\n"
            "Prefix = ${_qt_conf_prefix}\n"
            "Plugins = Qt6/plugins\n"
            "QmlImports = Qt6/qml\n")
    endif()

    unset(_qt_conf_prefix)
    unset(_qt_conf_dir)
endif()
