# Awen

A C++23 application framework built around Qt Quick, plus the apps on top of it.
Layout:

Qt Quick is the sole rendering backend, on windows, linux, macos, web
(emscripten/wasm, toolchain pinned in `.emscripten-version`) and android
(arm64-v8a, NDK pinned in `.android-ndk-version`; Qt's androiddeployqt
assembles the APK).

- `src/` — the framework: QML modules built with `qt_add_qml_module` — `awen.entity`
  (target `awen-entity`: the `entity` value type plus the `System`/`Systems`
  QML pair games derive per-frame logic from), `awen.gamepad` (target `awen-gamepad`: an SDL3-backed
  gamepad attached-property type — one SDL backend on desktop and wasm (SDL wraps
  the browser Gamepad API there), an inert stub on android; its Qt-free
  `awen-gamepad-core` is the unit-tested, coverage-observed part), `awen.input`
  (target `awen-input`: `Axis` folds key/controller/touch contributions into one
  clamped value through the `Action*` bindings and `Actions` router), `awen.command`
  (target `awen-command`, depends on awen.entity: the command bus — plain
  `{name, payload}` records posted to a `CommandQueue`, published once per tick
  and consumed by `Store`s through declared `CommandHandler`s; game intents only,
  simulation systems write entities directly) and `awen.shapes` (target
  `awen-shapes`: instrument primitives on QtQuick.Shapes, bearing-degree angles).
  There is no shared bootstrap: every app writes its own `main.cpp` and names it
  with `awen_add_executable`'s required `MAIN` keyword, duplication accepted so
  an app can load its QML its own way.
- `app/awen/` — the framework sample app (QML module `AwenApp`).
- `app/briarthorn/` — the briarthorn game (own license: `LICENSE.md` there — the
  rest of the repo is MIT). The `Briarthorn` QML module (`qml/Main.qml`); the
  game is implemented in QML. `qml/database/` holds the static definitions and
  `qml/model/` the live state they seed — see the database section below.
- `cmake/preset/` — composable presets; `cmake/triplets/` — overlay triplets
  (qt ports dynamic, everything else static; dependencies release-only, except
  the dual-config `x64-windows` triplet the windows debug preset needs).

## Build & test (Windows / MSVC)

- **Source VS18 vcvars64 first** or builds fail on missing MSVC/`type_traits`:
  `call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"`
- Configure: `cmake --preset windows-msvc-debug` (or `-release`). Qt is
  auto-discovered from a prebuilt kit (`C:\Qt`, `~/Qt`, or env `QT_ROOT_DIR`;
  see `cmake/qt-source.cmake`) — without one, vcpkg builds Qt from source (slow
  once, then binary-cached). `-DAWEN_QT=vcpkg|prebuilt|auto` pins the choice;
  steamos always uses vcpkg Qt (glibc floor). SDL3/gtest come from vcpkg either
  way.
- Build: `cmake --build --preset windows-msvc-debug`
- Test: `ctest --preset windows-msvc-debug`
- QML is embedded via qmlcachegen, so a release QML edit needs a rebuild. If a
  QML edit trips MSVC C4702 in Qt headers under /WX, that warning is already
  disabled on the briarthorn target.
- Desktop **debug** builds instead load `Main.qml` from the source tree, so
  qmlpreview live-reloads QML edits with no rebuild: build the
  `briarthorn-qmlpreview` target (`cmake --build --preset windows-msvc-debug
  --target briarthorn-qmlpreview`, or the `qmlpreview: briarthorn` task), which
  runs the app under the tool. `cmake/target/qmlpreview.cmake` locates
  qmlpreview — it is not an imported target, and vcpkg puts it in
  `tools/Qt6/bin` rather than the kit's `bin`. The `qmldir` beside each of
  briarthorn's singleton folders is what makes them resolve on that path, and a
  file using a type from another folder must directory-import it (`import
  "../themes"`) rather than lean on the compiled module — mirror singleton
  changes into `QML_SINGLETONS` too.
- The same connection carries QML/JavaScript debugging: `.vscode/launch.json`
  drives the Qt Qml extension (QML-only, plus a compound that pairs it with the
  C++ debugger), building through the `cmake: build briarthorn` task. Both need
  a **debug** preset selected in CMake Tools — `QT_QML_DEBUG` is Debug-only, and
  without it the app has no debug connection at all.

## Conventions

- **Almost Always Auto.** Declare locals and `constexpr` constants with `auto`,
  moving the type onto the right-hand side when it isn't already there:
  `auto v = Vec2{...}`, `const auto n = a + b`, `constexpr auto Step = 8`. Pin
  the type on the RHS when a bare literal would deduce the wrong one. Function
  parameters, return types (`-> T`), and non-static data members stay explicitly
  typed.
- Trailing return types everywhere: `auto f(...) -> T`. Allman braces, 4-space
  indent (clang-format; `clang-format` / `clang-format-check` build targets).
- **Data members initialize with braces**, not `=`: `bool ready_{false};`,
  `QTimer* timer_{nullptr};`, `int code{-1};` — for default member initializers
  in classes and structs alike (locals stay Almost Always Auto, above).
- `.cpp` files pull names in with `using` declarations at file scope and define
  members as `auto X::method(...)` — they do **not** reopen namespaces.
  File-local helpers and constants live in an anonymous `namespace {}`.
- **No non-const globals** — mutable state belongs to an object instance.
- Accessor/mutator pairs are `getX()` / `setX()`; a lone getter keeps its bare
  name (`alpha()`, `entities()`).
- **QML names go base-type-first.** A derived QML type's object and file name
  lead with the type it derives from, then the specialization: `SystemMovement`
  (a `System`), not `MovementSystem`. Briarthorn's systems live in
  `app/briarthorn/qml/systems/`.
- **Doc comments are Doxygen.** `///` with `@brief`, `@param`, `@return`;
  `@p name` for parameters; trailing `///<` for data members.
- **Commit messages are one line.** A single short imperative summary — no body,
  no trailers.

## Briarthorn's game database

Every static kind definition is one file under `app/briarthorn/qml/database/`,
in `entities/`, `weapons/`, `abilities/` or `personalities/`, registered in the
single list on the `Database`, `Abilities` or `Personalities` singleton — the
lookup table derives from that list, so adding a kind is a new file, a new
`Classification` and one line, never a switch to keep in step. `qml/model/`
holds the live state those rows seed and is allowed to import `../database`;
the database imports nothing back.

- **Stats are ratings, never quantities.** A `DataEntity` rates a kind 0..10 on
  the six stats and `GameRules` prices every rating into m/s, deg/s, m/s^2,
  metres, hit points and fuel units. Speed, acceleration, turn rate, fuel flow,
  detection range and seeker reach all come from there — a definition that
  spells out a physical number is a bug, and retuning the game means editing
  `GameRules.qml` alone.
- **An `Entity` defaults from its row.** Every stat and capability binds to the
  `DataEntity` its `classification` names, so a spawn site names a kind and
  overrides only what makes that one different; assigning nothing to `abilities`
  gives it the loadout its kind carries. `World.spawn(prefix, classification,
  props)` is the one spawn path.
- **A personality is stances plus switches, priced on envelopes.** A
  `Personality` row's stances name maneuvers from the model's `Maneuvers`
  registry, and its `Switch` rows express every distance as a fraction of a
  priced envelope (own weapon reach, the target's, detection range) — never
  metres. `SystemPersonality` attaches the live `PersonalityState` and owns
  `maneuvers`, `engageHold` and `engageHoldoff` on its entities; scenarios
  point `engageTarget` and the personality decides how to fight it, so a
  director-run entity (the menu demo's spawns) stays personality-free.
- **Ability input is generated, never written.** Adding an ability is four
  edits: the def under `database/abilities/` (carrying its own `defaultKey` and
  `defaultButton`), a line in the `Abilities` registry, a line in
  `CMakeLists.txt`, and its name in a `DataEntity.abilities` list. `Main.qml`
  builds one axis, key binding, pad binding and command per carried slot off the
  loadout, so it needs no edit at all — and `qml/input/Keymap.qml` is what the
  controls page rebinds, seeded from those defaults and stored as a diff.
