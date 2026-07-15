//! src/game — the raylib-free game core (simulation + state).
//!
//! CMake's add_library(briarthorn-game STATIC): the simulation and world state,
//! deliberately free of raylib and every platform library — that is what lets
//! Briarthorn (and the tests) run headless. The raylib graphics edge is a
//! separate archive (src/raylib/build.zig), and Briarthorn itself lives in the
//! app module (src/build.zig).

const std = @import("std");
const Ctx = @import("../../../../zig/Ctx.zig").Ctx;
const tests = @import("test/build.zig");

/// add_library(briarthorn-game STATIC). Returns the archive so the raylib edge,
/// the app, and the test can link it (target_link_libraries).
pub fn configure(c: *const Ctx) *std.Build.Step.Compile {
    const mod = c.module();
    c.addSources(mod, "app/briarthorn/src/game", &.{
        "Clock.cpp",
        "CommandBuffer.cpp",
        "Duration.cpp",
        "Entity.cpp",
        "Geo.cpp",
        "Vec2.cpp",
        "World.cpp",
        "systems/Movement.cpp",
    });

    // The game core links nothing — no raylib, no platform libraries. That is
    // what lets Briarthorn and the tests run headless.

    const lib = c.b.addLibrary(.{ .name = "briarthorn-game", .linkage = .static, .root_module = mod });
    c.applyLibC(lib); // android: point at the NDK libc file; no-op elsewhere.

    // add_subdirectory(test) — desktop only, matching CMake's
    // `if(BUILD_TESTING AND NOT ANDROID AND NOT EMSCRIPTEN)`.
    if (c.isDesktop()) tests.configure(c, lib);

    return lib;
}
