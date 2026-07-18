# awen.entity — entity state and the System/Systems pair games derive their
# per-frame logic from.

# SHARED except on wasm (one static binary there): a static module has no loadable
# plugin, so a Release loadFromModule fails to resolve `import awen.entity`.
set(_awen_entity_linkage "")
if(NOT EMSCRIPTEN)
    set(_awen_entity_linkage "SHARED")
endif()

qt_add_qml_module(awen-entity
    ${_awen_entity_linkage}
    URI awen.entity
    VERSION 1.0
    QML_FILES
        System.qml
        Systems.qml
    SOURCES
        Entity.h
)

target_link_libraries(awen-entity
    PUBLIC
        Qt6::Core
        Qt6::Quick
)

# qmlcachegen-generated code trips MSVC C4702 (unreachable return) inside Qt
# headers, which /WX would turn into an error — disable just that warning.
if(MSVC)
    target_compile_options(awen-entity PRIVATE /wd4702)
endif()

# Tests run natively only; the web and android presets set BUILD_TESTING=OFF.
if(BUILD_TESTING)
    add_subdirectory(test)
endif()
