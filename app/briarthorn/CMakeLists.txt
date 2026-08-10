project(briarthorn)

# The cue voices, one implementation per platform, both named Cue.qml so the
# type name is the same and Sfx never learns which it got. The browser build
# takes the silent one: the wasm Qt kit carries no QtMultimedia (Qt ships it for
# the multithreaded kit only, and this build is single-threaded), and an
# `import QtMultimedia` that resolves to nothing does not degrade — it stops
# Main.qml loading.
if(EMSCRIPTEN)
    set(QML_CUE qml/audio/wasm/Cue.qml)
else()
    set(QML_CUE qml/audio/Cue.qml)
endif()

set(QML_SINGLETONS
    qml/audio/Sfx.qml
    qml/commands/Verbs.qml
    qml/database/Abilities.qml
    qml/database/Database.qml
    qml/database/GameRules.qml
    qml/database/Names.qml
    qml/database/Personalities.qml
    qml/model/Geo.qml
    qml/model/Maneuvers.qml
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
        ${QML_CUE}
        qml/commands/CommandAbility.qml
        qml/commands/CommandSteer.qml
        qml/commands/CommandTarget.qml
        qml/commands/CommandThrottle.qml
        qml/database/Ability.qml
        qml/database/AbilityCountermeasure.qml
        qml/database/AbilityLaunch.qml
        qml/database/Classification.qml
        qml/database/Data.qml
        qml/database/DataEntity.qml
        qml/database/DataWeapon.qml
        qml/database/Envelope.qml
        qml/database/Personality.qml
        qml/database/Stance.qml
        qml/database/Stats.qml
        qml/database/Switch.qml
        qml/database/SwitchAmmoOut.qml
        qml/database/SwitchDecoy.qml
        qml/database/SwitchHealth.qml
        qml/database/SwitchOutbound.qml
        qml/database/SwitchRange.qml
        qml/database/SwitchThreat.qml
        qml/database/abilities/AbilityFlare.qml
        qml/database/abilities/AbilityLaunchGuided.qml
        qml/database/abilities/AbilityLaunchKinetic.qml
        qml/database/entities/DataAircraftFighter.qml
        qml/database/entities/DataAircraftFighterLight.qml
        qml/database/entities/DataDecoy.qml
        qml/database/entities/DataUnknown.qml
        qml/database/personalities/PersonalityAggressive.qml
        qml/database/personalities/PersonalityDefensive.qml
        qml/database/personalities/PersonalityDuelist.qml
        qml/database/personalities/PersonalityFearful.qml
        qml/database/personalities/PersonalityTactical.qml
        qml/database/weapons/DataMissileGuided.qml
        qml/database/weapons/DataMissileKinetic.qml
        qml/input/AbilityInput.qml
        qml/input/ActiveDevice.qml
        qml/input/Keymap.qml
        qml/model/AbilitySlot.qml
        qml/model/Detonation.qml
        qml/model/Entity.qml
        qml/model/Maneuver.qml
        qml/model/ManeuverCrank.qml
        qml/model/ManeuverEvade.qml
        qml/model/ManeuverFlee.qml
        qml/model/ManeuverFormation.qml
        qml/model/ManeuverNotch.qml
        qml/model/ManeuverOrbit.qml
        qml/model/ManeuverPursue.qml
        qml/model/Mode.qml
        qml/model/Obstacle.qml
        qml/model/PersonalityState.qml
        qml/model/RangeProjection.qml
        qml/model/Side.qml
        qml/model/StoreGame.qml
        qml/model/Track.qml
        qml/model/Weapon.qml
        qml/model/World.qml
        qml/scenarios/Scenario.qml
        qml/scenarios/ScenarioDuel.qml
        qml/scenarios/ScenarioMenu.qml
        qml/systems/SystemAbility.qml
        qml/systems/SystemAvoidance.qml
        qml/systems/SystemCollision.qml
        qml/systems/SystemCountermeasure.qml
        qml/systems/SystemCue.qml
        qml/systems/SystemDetection.qml
        qml/systems/SystemEngage.qml
        qml/systems/SystemFuel.qml
        qml/systems/SystemManeuver.qml
        qml/systems/SystemMission.qml
        qml/systems/SystemMovement.qml
        qml/systems/SystemPersonality.qml
        qml/systems/SystemThreat.qml
        qml/systems/SystemWeapon.qml
        qml/themes/Theme.qml
        qml/themes/ThemeAurora.qml
        qml/themes/ThemeCatppuccinMocha.qml
        qml/ui/AbilityButton.qml
        qml/ui/ControlCap.qml
        qml/ui/Joystick.qml
        qml/ui/MenuButton.qml
        qml/ui/MenuPage.qml
        qml/ui/RangeRing.qml
        qml/ui/Symbol.qml
        qml/ui/SymbolFlare.qml
        qml/ui/TouchAbilities.qml
        qml/ui/TouchArrow.qml
        qml/ui/ViewAbilities.qml
        qml/ui/ViewAlerts.qml
        qml/ui/ViewArming.qml
        qml/ui/ViewEnd.qml
        qml/ui/ViewEngagements.qml
        qml/ui/ViewHints.qml
        qml/ui/ViewHudOverlay.qml
        qml/ui/ViewMenu.qml
        qml/ui/ViewObstacles.qml
        qml/ui/ViewPause.qml
        qml/ui/ViewSettings.qml
        qml/ui/ViewSituation.qml
        qml/ui/ViewSituationAttack.qml
        qml/ui/ViewSituationOverview.qml
        qml/ui/ViewStatus.qml
        qml/ui/ViewTerrain.qml
        qml/ui/ViewThreat.qml
        qml/ui/ViewTopBar.qml
        qml/ui/ViewTracks.qml
        qml/ui/ViewTrails.qml
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

# What the sounding Cue plays through. QtMultimedia only for QSoundEffect, which
# lives in the module's core and decodes WAV itself — no media backend is pulled
# in. The wasm build has no QtMultimedia and no need of it: its Cue is silent.
if(NOT EMSCRIPTEN)
    target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Multimedia)
endif()

# A resource of their own rather than the QML module's RESOURCES, so a cue's URL
# has one form and not two: a desktop debug build loads Main.qml from the source
# tree (see below) and a relative path would then resolve outside the module.
# BASE strips the directory, leaving qrc:/audio/<role>.wav on every config.
#
# Not shipped to the browser, where the silent Cue never resolves the urls Sfx
# hands it: the web build is downloaded before it runs, so a cue it cannot play
# is not merely dead weight in the binary, it is dead weight on the wire.
if(NOT EMSCRIPTEN)
    qt_add_resources(${PROJECT_NAME} briarthorn_audio
        PREFIX "/audio"
        BASE assets/audio
        FILES
            assets/audio/back.wav
            assets/audio/impact.wav
            assets/audio/launch.wav
            assets/audio/lock.wav
            assets/audio/navigate.wav
            assets/audio/press.wav
            assets/audio/threat.wav
    )
endif()

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
