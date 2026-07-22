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
  `src/awen/app/` (target `awen-app`) is the shared `awen::runApp` bootstrap
  behind the `main()` that `awen_add_executable` generates per app.
- `app/awen/` — the framework sample app (QML module `AwenApp`).
- `app/briarthorn/` — the briarthorn game (own license: `LICENSE.md` there — the
  rest of the repo is MIT). The `Briarthorn` QML module (`qml/Main.qml`) on the
  framework's shared bootstrap; the game is implemented in QML.
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
- QML is embedded via qmlcachegen, so QML edits need a rebuild. If a QML edit
  trips MSVC C4702 in Qt headers under /WX, that warning is already disabled on
  the briarthorn target.

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
