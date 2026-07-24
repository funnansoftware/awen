project(briarthorn)

set(QML_SINGLETONS
    qml/commands/Verbs.qml
    qml/model/Abilities.qml
    qml/model/Database.qml
    qml/themes/Style.qml
)

set_source_files_properties(${QML_SINGLETONS}
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE
)

# Briarthorn — the game, built in QML on the awen framework; own license, see
# LICENSE.md. The shared bootstrap loads the Briarthorn QML module.
awen_add_executable(${PROJECT_NAME}
    URI Briarthorn
    VERSION 1.0
    QML_FILES
        qml/Main.qml
        qml/commands/CommandAbility.qml
        qml/commands/CommandSteer.qml
        qml/commands/CommandThrottle.qml
        qml/model/Ability.qml
        qml/model/AbilityFlare.qml
        qml/model/AbilityLaunch.qml
        qml/model/AbilitySlot.qml
        qml/model/Classification.qml
        qml/model/Data.qml
        qml/model/DataWeapon.qml
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
        qml/ui/Joystick.qml
        qml/ui/RangeRing.qml
        qml/ui/Symbol.qml
        qml/ui/SymbolFlare.qml
        qml/ui/ViewEngagements.qml
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
