//! src — the app: an executable module that links the game core and the raylib
//! graphics edge. The CMakeLists.txt analog: add_subdirectory(game);
//! add_subdirectory(raylib); add_executable (or a SHARED library on android / a
//! static library + emcc on emscripten); target_sources(main.cpp);
//! target_link_libraries(PRIVATE briarthorn-game briarthorn-raylib).

const std = @import("std");
const config = @import("../../../zig/config.zig");
const Ctx = @import("../../../zig/Ctx.zig").Ctx;
const game = @import("game/build.zig");
const raylib = @import("raylib/build.zig");
const android = @import("../../../zig/android.zig");
const emscripten = @import("../../../zig/emscripten.zig");

pub fn configure(c: *const Ctx) void {
    // add_subdirectory(game); add_subdirectory(raylib). The game core (raylib-free)
    // and the raylib graphics edge are separate archives; the edge links the core,
    // so linking the edge pulls the core in transitively behind it.
    const game_lib = game.configure(c);
    const raylib_lib = raylib.configure(c, game_lib);

    // The app: the Briarthorn owning object plus the entry point.
    const app = c.module();
    c.addSources(app, "app/briarthorn/src", &.{ "Briarthorn.cpp", "main.cpp" });

    // What "the app" is — and how the libraries are linked into it — depends on
    // the platform, exactly as in src/CMakeLists.txt.
    switch (c.platform) {
        .windows, .linux, .macos => {
            // target_link_libraries(app PRIVATE briarthorn-raylib); briarthorn-game
            // (and raylib and the system libs) come transitively from it, dependency
            // -ordered after the edge for the single-pass linker.
            app.linkLibrary(raylib_lib);

            // Windows: embed the application icon into the .exe. Zig's built-in
            // resource compiler (resinator) compiles src/briarthorn.rc and links
            // it, so Explorer, the taskbar, and Alt-Tab show the icon — the
            // native-build analog of the MSVC .rc handling in src/CMakeLists.txt.
            if (c.platform == .windows)
                app.addWin32ResourceFile(.{ .file = c.b.path("app/briarthorn/src/briarthorn.rc") });

            const exe = c.b.addExecutable(.{ .name = config.app_name, .root_module = app });
            c.install(exe, "bin");
            c.runStep(exe);
        },

        .android => {
            // add_library(briarthorn SHARED) + NDK linking + APK packaging. The
            // edge is linked via Zig, so the game core comes with it transitively.
            android.finishApp(c, app, raylib_lib);
            c.stubDesktopOnlySteps();
        },
        .emscripten => {
            // static library + emcc -> .html/.js/.wasm. emcc gets each archive
            // explicitly (no Zig-managed transitive link), so both are passed.
            emscripten.finishApp(c, app, game_lib, raylib_lib);
            c.stubDesktopOnlySteps();
        },
    }
}
