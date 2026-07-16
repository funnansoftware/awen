# Make the apps runnable from the BUILD tree on Windows.
#
# vcpkg's app-local deployment copies the Qt DLLs next to each executable. That
# defeats Qt's relocatable prefix detection, which derives the install prefix
# from the location of Qt6Core: with the DLL sitting beside the .exe, the prefix
# resolves to the executable's own directory, which holds no plugins or QML
# imports. QGuiApplication then aborts with "no Qt platform plugin could be
# initialized" before main gets anywhere.
#
# qt.conf is Qt's sanctioned override for exactly this: Qt reads it from the
# application directory at startup and takes its paths from there. Point it back
# at the vcpkg-installed Qt tree. The installed app needs none of this — the
# deploy script's windeployqt writes an equivalent qt.conf of its own.
#
# The paths mirror vcpkg's Qt layout (<prefix>/Qt6/plugins and <prefix>/Qt6/qml,
# with the debug build under the triplet's debug/ subdirectory), so they differ
# from Qt's defaults and must be spelled out.
#
# Include after qt_standard_project_setup(), which is what points the runtime
# output directory at the build root.
if(WIN32 AND DEFINED VCPKG_INSTALLED_DIR)
    if(CMAKE_BUILD_TYPE STREQUAL "Debug")
        set(_qt_conf_prefix "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/debug")
    else()
        set(_qt_conf_prefix "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}")
    endif()

    if(CMAKE_RUNTIME_OUTPUT_DIRECTORY)
        set(_qt_conf_dir "${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
    else()
        set(_qt_conf_dir "${CMAKE_BINARY_DIR}")
    endif()

    file(WRITE "${_qt_conf_dir}/qt.conf"
        "[Paths]\n"
        "Prefix = ${_qt_conf_prefix}\n"
        "Plugins = Qt6/plugins\n"
        "QmlImports = Qt6/qml\n")

    unset(_qt_conf_prefix)
    unset(_qt_conf_dir)
endif()
