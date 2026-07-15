//! src/raylib — the raylib graphics edge, a linkable library module. The
//! CMakeLists.txt analog: add_library(briarthorn-raylib STATIC) +
//! target_link_libraries(briarthorn-raylib PUBLIC briarthorn-game raylib).

const std = @import("std");
const Ctx = @import("../../../../zig/Ctx.zig").Ctx;

/// add_library(briarthorn-raylib STATIC): the Renderer/Window that present the
/// game core and own the graphics stack. Links [game] (it reads the world to
/// draw it and record input) and, on desktop, the raylib/glfw stack. Returns the
/// archive so the app can link it (target_link_libraries).
pub fn configure(c: *const Ctx, game: *std.Build.Step.Compile) *std.Build.Step.Compile {
    const mod = c.module();
    c.addSources(mod, "app/briarthorn/src/raylib", &.{
        "Renderer.cpp",
        "Window.cpp",
    });

    // target_link_libraries(briarthorn-raylib PUBLIC briarthorn-game): the edge
    // reads the game core to draw it and record input.
    mod.linkLibrary(game);

    // target_link_libraries(... PUBLIC raylib) + glfw. Desktop links the graphics
    // stack here so the app inherits it transitively (raylib named before glfw3
    // for the single-pass linker). Android/emscripten link raylib in their
    // platform finishApp (an object file / an emcc argument).
    if (c.isDesktop()) {
        c.linkVcpkg(mod, "raylib");
        c.linkVcpkg(mod, "glfw3");
        c.linkSystemLibs(mod);
    }

    const lib = c.b.addLibrary(.{ .name = "briarthorn-raylib", .linkage = .static, .root_module = mod });
    c.applyLibC(lib); // android: point at the NDK libc file; no-op elsewhere.

    return lib;
}
