# awen.command — the command bus games drive state changes through: plain
# {name, payload} records posted to a queue, published once per tick, and
# consumed by stores through their declared handlers.
awen_add_qml_module(awen-command
    URI awen.command
    VERSION 1.0
    # The queue and store base derive awen.entity's System, so the import
    # scan must link that module into static (wasm) apps.
    DEPENDENCIES
        awen.entity
    QML_FILES
        Command.qml
        CommandHandler.qml
        CommandQueue.qml
        Store.qml
)

# The System base resolves from awen.entity's qmldir at load; build it first.
add_dependencies(awen-command awen-entity)

# Tests run natively only; the web and android presets set BUILD_TESTING=OFF.
if(BUILD_TESTING)
    add_subdirectory(test)
endif()
