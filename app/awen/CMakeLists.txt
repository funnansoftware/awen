# The framework sample app: a thin Qt bootstrap loading the AwenApp QML module.
# On android it packages under Qt's default template identity.
awen_add_executable(awen
    URI AwenApp
    VERSION 1.0
    QML_FILES
        Main.qml
    IMPORTS
        awen.entity
)

target_sources(awen
    PRIVATE
        main.cpp
)

target_link_libraries(awen
    PRIVATE
        awen-entity
)
