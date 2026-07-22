# awen.entity — entity state and the System/Systems pair games derive their
# per-frame logic from.
awen_add_qml_module(awen-entity
    URI awen.entity
    VERSION 1.0
    QML_FILES
        System.qml
        SystemGroup.qml
        Systems.qml
    SOURCES
        Entity.h
)

# Tests run natively only; the web and android presets set BUILD_TESTING=OFF.
if(BUILD_TESTING)
    add_subdirectory(test)
endif()
