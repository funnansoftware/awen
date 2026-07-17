# Awen

A C++23 application framework built around Qt Quick, plus the apps on top of it.
Layout:

Qt Quick is the sole rendering backend, on windows, linux, macos, web
(emscripten/wasm, toolchain pinned in `.emscripten-version`) and android
(arm64-v8a, NDK pinned in `.android-ndk-version`; Qt's androiddeployqt
assembles the APK).

- `src/` — the framework: QML modules built with `qt_add_qml_module` — `awen.entity`
  (target `awen-entity`) and `awen.gamepad` (target `awen-gamepad`: an SDL3-backed
  gamepad attached-property type, desktop-only SDL with an inert stub on wasm/android;
  its Qt-free `awen-gamepad-core` is the unit-tested, coverage-observed part).
- `app/awen/` — the framework sample app (QML module `AwenApp`).
- `app/briarthorn/` — the briarthorn game (own license: `LICENSE.md` there — the
  rest of the repo is MIT). Flat: `main.cpp` is a thin Qt bootstrap that loads
  the `Briarthorn` QML module (`qml/Main.qml`); the game is implemented in QML.
- `cmake/preset/` — composable presets; `cmake/triplets/` — overlay triplets
  (qt ports dynamic, everything else static; dependencies release-only, except
  the dual-config `x64-windows` triplet the windows debug preset needs).

## Build & test (Windows / MSVC)

- **Source VS18 vcvars64 first** or builds fail on missing MSVC/`type_traits`:
  `call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"`
- Configure: `cmake --preset windows-msvc-debug` (or `-release`; first configure
  builds Qt via vcpkg — slow once, then binary-cached).
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
- `.cpp` files pull names in with `using` declarations at file scope and define
  members as `auto X::method(...)` — they do **not** reopen namespaces.
  File-local helpers and constants live in an anonymous `namespace {}`.
- **No non-const globals** — mutable state belongs to an object instance.
- Accessor/mutator pairs are `getX()` / `setX()`; a lone getter keeps its bare
  name (`alpha()`, `entities()`).
- **Doc comments are Doxygen.** `///` with `@brief`, `@param`, `@return`;
  `@p name` for parameters; trailing `///<` for data members.
- **Commit messages are one line.** A single short imperative summary — no body,
  no trailers.
