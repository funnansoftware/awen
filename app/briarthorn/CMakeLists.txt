project(briarthorn)

set(QML_SINGLETONS
    qml/commands/Verbs.qml
    qml/database/Abilities.qml
    qml/database/Database.qml
    qml/database/GameRules.qml
    qml/themes/Style.qml
)

set_source_files_properties(${QML_SINGLETONS}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

# Briarthorn — the game, built in QML on the awen framework; own license, see
# LICENSE.md. main.cpp loads Main.qml, from the source tree or the compiled
# Briarthorn module depending on the config (see the debug block below).
awen_add_executable(${PROJECT_NAME}
    URI Briarthorn
    VERSION 1.0
    MAIN main.cpp
    QML_FILES
        qml/Main.qml
        qml/commands/CommandAbility.qml
        qml/commands/CommandSteer.qml
        qml/commands/CommandThrottle.qml
        qml/database/Ability.qml
        qml/database/AbilityCountermeasure.qml
        qml/database/AbilityLaunch.qml
        qml/database/Classification.qml
        qml/database/Data.qml
        qml/database/DataEntity.qml
        qml/database/DataWeapon.qml
        qml/database/Stats.qml
        qml/database/abilities/AbilityFlare.qml
        qml/database/abilities/AbilityLaunchGuided.qml
        qml/database/abilities/AbilityLaunchKinetic.qml
        qml/database/entities/DataAircraftFighter.qml
        qml/database/entities/DataDecoy.qml
        qml/database/entities/DataUnknown.qml
        qml/database/weapons/DataMissileGuided.qml
        qml/database/weapons/DataMissileKinetic.qml
        qml/input/AbilityInput.qml
        qml/input/ActiveDevice.qml
        qml/input/Keymap.qml
        qml/model/AbilitySlot.qml
        qml/model/Detonation.qml
        qml/model/Entity.qml
        qml/model/RangeProjection.qml
        qml/model/Side.qml
        qml/model/StoreGame.qml
        qml/model/Track.qml
        qml/model/Weapon.qml
        qml/model/World.qml
        qml/scenarios/Scenario.qml
        qml/scenarios/ScenarioDuel.qml
        qml/systems/SystemAbility.qml
        qml/systems/SystemCountermeasure.qml
        qml/systems/SystemDetection.qml
        qml/systems/SystemEngage.qml
        qml/systems/SystemFuel.qml
        qml/systems/SystemMovement.qml
        qml/systems/SystemPursuit.qml
        qml/systems/SystemThreat.qml
        qml/systems/SystemWeapon.qml
        qml/themes/Aurora.qml
        qml/ui/AbilityButton.qml
        qml/ui/ControlCap.qml
        qml/ui/Joystick.qml
        qml/ui/RangeRing.qml
        qml/ui/Symbol.qml
        qml/ui/SymbolFlare.qml
        qml/ui/TouchAbilities.qml
        qml/ui/TouchArrow.qml
        qml/ui/ViewAbilities.qml
        qml/ui/ViewEngagements.qml
        qml/ui/ViewHints.qml
        qml/ui/ViewSettings.qml
        qml/ui/ViewSituation.qml
        qml/ui/ViewSituationAttack.qml
        qml/ui/ViewStatus.qml
        qml/ui/ViewTopBar.qml
        qml/ui/ViewTracks.qml
        ${QML_SINGLETONS}
    AWEN_MODULES
        buildinfo
        command
        entity
        gamepad
        input
        shapes
    WINDOWS_ICON briarthorn.ico
    # The briarthorn.game entry page, embedding the app in a bounded view; Qt's
    # generated briarthorn.html stays as a debug fallback.
    WEB_SHELL web/index.html
)

# qmlpreview live-reload: a desktop debug build loads Main.qml from the source
# tree instead of the compiled module, because the engine only reloads QML that
# came from a file URL. Main.qml's directory imports then resolve on disk as
# well, so every game file reloads — each folder's singletons through the qmldir
# beside them. The cross builds have no source tree on the device and stay on
# the module path.
if(NOT EMSCRIPTEN AND NOT ANDROID)
    target_compile_definitions(${PROJECT_NAME} PRIVATE
        # QT_QML_DEBUG instantiates QQmlDebuggingEnabler in main.cpp's translation
        # unit, opening the debug connection when the app is started with
        # -qmljsdebugger=... — which is how qmlpreview launches it. Debug only:
        # with the debug server on, the engine wants QML imports the deploy step
        # does not ship.
        $<$<CONFIG:Debug>:QT_QML_DEBUG>
        # Absolute path to the QML sources for main.cpp's file load. Forward
        # slashes from CMake are fine for QUrl::fromLocalFile.
        $<$<CONFIG:Debug>:BRIARTHORN_QML_SOURCE_DIR="${CMAKE_CURRENT_SOURCE_DIR}/qml">
    )
endif()

if(ANDROID)
    # Package identity and launcher assets; androiddeployqt overlays android/
    # onto Qt's package template.
    set_target_properties(${PROJECT_NAME} PROPERTIES
        QT_ANDROID_PACKAGE_NAME "com.funnansoftware.briarthorn"
        QT_ANDROID_VERSION_CODE 1
        QT_ANDROID_VERSION_NAME "1.0"
        QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
    )
endif()
