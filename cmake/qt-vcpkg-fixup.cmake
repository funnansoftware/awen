# Work around a vcpkg Qt6 packaging bug on x64-windows: the installed
# Qt6CoreConfigExtras.cmake hardcodes QT6_DEBUG_POSTFIX to "" even though Qt's
# debug DLLs are built with a "d" suffix (e.g. Qt6Quickd.dll). The empty
# postfix makes qt6_deploy_qml_imports pick release QML plugins for debug
# builds, after which windeployqt fails resolving their release-named
# transitive dependencies in the debug bin directory.
#
# Rewrite the offending line in the installed config so Qt's normal deploy
# machinery selects debug plugins on its own. Idempotent (only writes when the
# content actually changes) and re-applied on every configure, so it survives
# `vcpkg install` overwrites — and no-ops entirely if a newer port fixes the
# postfix. Observed with the qtbase 6.10 port; unverified against 6.11 — delete
# once a Windows debug deploy succeeds without it.

if(WIN32 AND CMAKE_HOST_WIN32 AND DEFINED VCPKG_INSTALLED_DIR)
    set(_qt6_core_extras
        "${VCPKG_INSTALLED_DIR}/${VCPKG_TARGET_TRIPLET}/share/Qt6Core/Qt6CoreConfigExtras.cmake")

    if(EXISTS "${_qt6_core_extras}")
        file(READ "${_qt6_core_extras}" _qt6_core_extras_content)
        string(REPLACE
            "set(QT6_DEBUG_POSTFIX \"\")"
            "set(QT6_DEBUG_POSTFIX \"d\")"
            _qt6_core_extras_patched
            "${_qt6_core_extras_content}")

        if(NOT _qt6_core_extras_patched STREQUAL _qt6_core_extras_content)
            file(WRITE "${_qt6_core_extras}" "${_qt6_core_extras_patched}")
            message(STATUS
                "Patched ${_qt6_core_extras}: QT6_DEBUG_POSTFIX = \"d\"")
        endif()

        unset(_qt6_core_extras_content)
        unset(_qt6_core_extras_patched)
    endif()

    unset(_qt6_core_extras)
endif()
