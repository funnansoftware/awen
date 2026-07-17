qt_add_executable(awen)

target_sources(${PROJECT_NAME}
    PRIVATE
        main.cpp
)

qt_add_qml_module(${PROJECT_NAME}
    URI AwenApp
    VERSION 1.0
    QML_FILES
        Main.qml
    IMPORTS
        awen.entity
)

# No QT_QML_DEBUG here: enabling the QML debug server makes the engine skip the
# qmlcachegen-compiled units and re-resolve imports from source, which then
# demands the optional qtquick2plugin that the deploy step does not ship —
# loadFromModule("AwenApp", "Main") fails at startup. briarthorn omits it for
# the same reason.

target_link_libraries(${PROJECT_NAME}
    PRIVATE
        awen-entity
        Qt6::Quick
)

if(EMSCRIPTEN)
    # Embed ":/qt/etc/qt.conf" so QLibraryInfo skips getRelocatablePrefix() and its
    # debug-only Q_ASSERT_X abort on this static wasm build. See the fuller note in
    # app/briarthorn/CMakeLists.txt. wasm-only; alias lands it at
    # exactly :/qt/etc/qt.conf.
    set_source_files_properties(
        "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
        PROPERTIES QT_RESOURCE_ALIAS qt.conf
    )
    qt_add_resources(${PROJECT_NAME} awen_wasm_qt_conf
        PREFIX "/qt/etc"
        FILES "${CMAKE_SOURCE_DIR}/cmake/wasm/qt.conf"
    )

    # Qt is linked into the .js/.wasm rather than deployed alongside, so ship the
    # generated bundle; see app/briarthorn/CMakeLists.txt.
    install(FILES
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/awen.html"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/awen.js"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/awen.wasm"
        DESTINATION web
    )

    install(FILES
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/qtloader.js"
        "$<TARGET_FILE_DIR:${PROJECT_NAME}>/awen.worker.js"
        DESTINATION web
        OPTIONAL
    )

    return()
endif()

if(ANDROID)
    # The framework sample packages under Qt's default template identity; see
    # app/briarthorn/CMakeLists.txt for the apk mechanics.
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/android-build/awen.apk"
        DESTINATION android
    )

    return()
endif()

install(TARGETS ${PROJECT_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET ${PROJECT_NAME}
    OUTPUT_SCRIPT deploy_script
    NO_UNSUPPORTED_PLATFORM_ERROR
    NO_TRANSLATIONS
)

install(SCRIPT ${deploy_script})

