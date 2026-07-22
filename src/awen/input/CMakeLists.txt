# awen.input — the input-fold layer: axes fold every source's contribution
# into one clamped value, and actions bind keys, controller buttons and
# gamepad axes onto them.
awen_add_qml_module(awen-input
    URI awen.input
    VERSION 1.0
    QML_FILES
        Action.qml
        ActionAxis.qml
        ActionButton.qml
        ActionDigital.qml
        ActionKey.qml
        Actions.qml
        Axis.qml
)

# Tests run natively only; the web and android presets set BUILD_TESTING=OFF.
if(BUILD_TESTING)
    add_subdirectory(test)
endif()
