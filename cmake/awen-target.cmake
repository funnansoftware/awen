# The project's two target patterns: a framework QML module and a Qt Quick app
# with its per-platform install/deploy story. Extra arguments forward to
# qt_add_qml_module (URI, VERSION, QML_FILES, SOURCES, IMPORTS, ...).

# A framework QML module: SHARED except on wasm (one static binary there) — a
# static module has no loadable plugin, so a Release loadFromModule fails to
# resolve the import.
function(awen_add_qml_module target)
    set(linkage "")
    if(NOT EMSCRIPTEN)
        set(linkage "SHARED")
    endif()

    qt_add_qml_module(${target}
        ${linkage}
        ${ARGN}
    )

    target_link_libraries(${target}
        PUBLIC
            Qt6::Core
            Qt6::Quick
    )

    # qmlcachegen-generated code trips MSVC C4702 (unreachable return) inside Qt
    # headers, which /WX would turn into an error — disable just that warning.
    if(MSVC)
        target_compile_options(${target} PRIVATE /wd4702)
    endif()
endfunction()

# A Qt Quick app: the executable+module pair plus per-platform install/deploy.
# Callers add sources, awen-module links, and platform extras after the call —
# Qt finalization is deferred to the end of the calling directory.
function(awen_add_executable target)
    qt_add_executable(${target})

    qt_add_qml_module(${target}
        ${ARGN}
    )

    # No QT_QML_DEBUG: the QML debug server bypasses the compiled units and
    # demands the optional qtquick2plugin the deploy step does not ship, failing
    # startup.

    target_link_libraries(${target} PRIVATE Qt6::Quick)

    # qmlcachegen-generated code trips MSVC C4702 (unreachable return) inside Qt
    # headers, which /WX would turn into an error — disable just that warning.
    if(MSVC)
        target_compile_options(${target} PRIVATE /wd4702)
    endif()

    # macOS needs an .app bundle for macdeployqt; a plain executable fails to
    # launch after install. Ignored off-Apple.
    set_target_properties(${target} PROPERTIES
        MACOSX_BUNDLE TRUE
    )

    if(EMSCRIPTEN)
        # Embed ":/qt/etc/qt.conf" so QLibraryInfo skips getRelocatablePrefix(),
        # whose debug-only assert aborts this static wasm build at startup.
        # wasm-only: on desktop a forced Prefix would break plugin/QML resolution.
        set_source_files_properties(
            "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
            PROPERTIES QT_RESOURCE_ALIAS qt.conf
        )
        qt_add_resources(${target} ${target}_wasm_qt_conf
            PREFIX "/qt/etc"
            FILES "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
        )

        # Qt is linked into the .js/.wasm, so ship the generated bundle; the
        # install directory can then be served as-is.
        install(FILES
            "$<TARGET_FILE_DIR:${target}>/${target}.html"
            "$<TARGET_FILE_DIR:${target}>/${target}.js"
            "$<TARGET_FILE_DIR:${target}>/${target}.wasm"
            DESTINATION web
        )

        # Only emitted for some configurations, so optional rather than predicted.
        install(FILES
            "$<TARGET_FILE_DIR:${target}>/qtloader.js"
            "$<TARGET_FILE_DIR:${target}>/${target}.worker.js"
            DESTINATION web
            OPTIONAL
        )
    elseif(ANDROID)
        # androiddeployqt assembles the APK during a plain build (apk_all is in
        # ALL); ship it from the build tree.
        install(FILES "${CMAKE_CURRENT_BINARY_DIR}/android-build/${target}.apk"
            DESTINATION android
        )
    else()
        install(TARGETS ${target}
            BUNDLE DESTINATION .
            RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
            LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
        )

        # Deploy the Qt libraries, platform plugins and QML imports next to the
        # installed app.
        qt_generate_deploy_qml_app_script(
            TARGET ${target}
            OUTPUT_SCRIPT deploy_script
            NO_UNSUPPORTED_PLATFORM_ERROR
            NO_TRANSLATIONS
        )

        install(SCRIPT ${deploy_script})
    endif()
endfunction()
