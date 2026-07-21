# The framework sample app: the AwenApp QML module on the shared bootstrap.
# On android it packages under Qt's default template identity.
awen_add_executable(awen
    URI AwenApp
    VERSION 1.0
    QML_FILES
        Main.qml
        StressScope.qml
    AWEN_MODULES
        entity
        shapes
)
