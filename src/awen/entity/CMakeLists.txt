

qt_add_qml_module(awen-entity
    URI awen.entity
    VERSION 1.0
    QML_FILES
    SOURCES
        Entity.h
)


target_link_libraries(${PROJECT_NAME}
    PUBLIC
        Qt6::Core
        Qt6::Quick
)