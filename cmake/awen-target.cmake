# The project's two target patterns: a framework QML module and a Qt Quick app
# with its per-platform install/deploy story.

# A framework QML module: SHARED except on wasm (one static binary there) — a
# static module has no loadable plugin, so a Release loadFromModule fails to
# resolve the import. Arguments forward to qt_add_qml_module (URI, VERSION,
# QML_FILES, SOURCES, ...).
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

# A Qt Quick app: the executable+module pair on the generated awen::runApp
# bootstrap, per-platform install/deploy, and a headless smoke test. The
# keywords below are consumed here; everything else forwards to
# qt_add_qml_module. Callers add platform extras after the call — Qt
# finalization is deferred to the end of the calling directory.
#   AWEN_MODULES <name>... — framework modules: imports awen.<name> and links awen-<name>.
#   WINDOWS_ICON <ico>     — embedded into the .exe via a generated .rc.
#   WEB_SHELL <html>       — the wasm entry page, installed as web/<target>/index.html.
#   MAIN <cpp>             — custom bootstrap replacing the generated main(); it
#                            should still call awen::runApp (see App.h).
#   NO_SMOKE_TEST          — skip the auto-registered tst_<target>_loads.
function(awen_add_executable target)
    cmake_parse_arguments(PARSE_ARGV 1 arg "NO_SMOKE_TEST" "URI;MAIN;WINDOWS_ICON;WEB_SHELL" "AWEN_MODULES")
    if(NOT arg_URI)
        message(FATAL_ERROR "awen_add_executable(${target}) requires URI")
    endif()

    qt_add_executable(${target})

    set(imports "")
    foreach(module IN LISTS arg_AWEN_MODULES)
        list(APPEND imports awen.${module})
    endforeach()
    if(imports)
        set(imports IMPORTS ${imports})
    endif()

    # IMPORTS tells the import scan (qmllint, deploy) that the QML files depend
    # on the framework modules; the types come from the linked modules below.
    qt_add_qml_module(${target}
        URI ${arg_URI}
        ${imports}
        ${arg_UNPARSED_ARGUMENTS}
    )

    # No QT_QML_DEBUG: the QML debug server bypasses the compiled units and
    # demands the optional qtquick2plugin the deploy step does not ship, failing
    # startup.

    # The generated main keeps main() an object of the app target itself — a
    # main() in a static library would be dropped from the android MODULE .so.
    if(arg_MAIN)
        target_sources(${target} PRIVATE ${arg_MAIN})
    else()
        set(AWEN_APP_TARGET ${target})
        set(AWEN_APP_URI ${arg_URI})
        configure_file("${CMAKE_SOURCE_DIR}/src/awen/app/main.cpp.in" "${target}_main.cpp" @ONLY)
        target_sources(${target} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/${target}_main.cpp")
    endif()
    target_link_libraries(${target} PRIVATE awen-app)

    foreach(module IN LISTS arg_AWEN_MODULES)
        target_link_libraries(${target} PRIVATE awen-${module})
    endforeach()

    # Windows: embed the icon via a generated .rc — the resource with the lowest
    # id is the .exe icon, so id 1. rc.exe accepts the forward-slash absolute
    # path; RC is enabled at the root (enable_language is file-scope-only).
    if(WIN32 AND arg_WINDOWS_ICON)
        get_filename_component(ico "${arg_WINDOWS_ICON}" ABSOLUTE)
        file(CONFIGURE OUTPUT "${target}.rc" CONTENT "1 ICON \"${ico}\"\n" @ONLY)
        target_sources(${target} PRIVATE "${CMAKE_CURRENT_BINARY_DIR}/${target}.rc")
    endif()

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

        # Each app ships into its own web/<target>/ directory — an independently
        # servable docroot, so one app's entry page never collides with another's.
        # Qt is linked into the .js/.wasm, so ship the generated bundle; the
        # directory can then be served as-is.
        install(FILES
            "$<TARGET_FILE_DIR:${target}>/${target}.html"
            "$<TARGET_FILE_DIR:${target}>/${target}.js"
            "$<TARGET_FILE_DIR:${target}>/${target}.wasm"
            DESTINATION web/${target}
        )

        # Only emitted for some configurations, so optional rather than predicted.
        install(FILES
            "$<TARGET_FILE_DIR:${target}>/qtloader.js"
            "$<TARGET_FILE_DIR:${target}>/${target}.worker.js"
            DESTINATION web/${target}
            OPTIONAL
        )

        # The shared shell machinery an app's custom entry page builds on.
        install(FILES "${CMAKE_SOURCE_DIR}/cmake/wasm/awen-shell.js"
            DESTINATION web/${target}
        )

        # The app's branded entry page becomes web/<target>/index.html — the
        # default document served for that app. Without it the app serves Qt's
        # generated <target>.html.
        if(arg_WEB_SHELL)
            install(FILES "${arg_WEB_SHELL}"
                DESTINATION web/${target}
                RENAME index.html
            )
        endif()
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

    # Headless smoke test: run the real app (minimal platform, software scene
    # graph) and quit via the awen::runApp seam — a clean exit proves Main.qml
    # and its imports load. TIMEOUT keeps a seam-less custom MAIN from hanging ctest.
    if(BUILD_TESTING AND NOT EMSCRIPTEN AND NOT ANDROID AND NOT arg_NO_SMOKE_TEST)
        add_test(NAME tst_${target}_loads COMMAND ${target})
        set_tests_properties(tst_${target}_loads PROPERTIES
            ENVIRONMENT "AWEN_SMOKE_QUIT_MS=3000;QT_QPA_PLATFORM=minimal;QSG_RHI_BACKEND=software"
            TIMEOUT 60
        )
        # A build-tree run has no qt.conf pointing at the in-project QML modules
        # (that file is written on Windows only), so Release's loadFromModule
        # needs the import path or it fails with "No module named <Uri> found".
        set_property(TEST tst_${target}_loads APPEND PROPERTY ENVIRONMENT_MODIFICATION
            "QML_IMPORT_PATH=path_list_append:${QT_QML_OUTPUT_DIRECTORY}"
        )
    endif()
endfunction()
