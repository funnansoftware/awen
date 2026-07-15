# Awen

A C++23 application framework built around Qt Quick, plus the apps on top of it.
Layout:

- `src/` — the framework: QML modules (`awen.entity`, target `awen-entity`) built
  with `qt_add_qml_module`. Only builds when the `qt` vcpkg manifest feature is
  active (the desktop presets set it).
- `app/awen/` — the framework sample app (QML module `AwenApp`).
- `app/briarthorn/` — the briarthorn game (own license: `LICENSE.md` there — the
  rest of the repo is MIT). Its layers: `src/game` (renderer-free simulation),
  `src/quick` (Qt Quick edge; defines the `briarthorn` executable when qt is on),
  `src/raylib` (raylib edge for zig/android/web builds).
- `cmake/preset/` — composable presets; `cmake/triplets/` — overlay triplets
  (qt ports dynamic, everything else static; `-zig` triplets chainload
  `cmake/toolchain/zig-*.cmake`); `cmake/vcpkg/ports/` — raylib overlay port.
- `build.zig` + `zig/` — the parallel zig build (no Qt; raylib renderer).

## Build & test (Windows / MSVC)

- **Source VS18 vcvars64 first** or builds fail on missing MSVC/`type_traits`:
  `call "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"`
- Configure: `cmake --preset windows-msvc-debug` (or `-release`; first configure
  builds Qt via vcpkg — slow once, then binary-cached).
- Build: `cmake --build --preset windows-msvc-debug`
- Test: `ctest --preset windows-msvc-debug`
- Zig build (raylib renderer, no Qt): `zig build` / `zig build test`.
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
