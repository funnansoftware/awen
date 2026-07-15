const std = @import("std");

// Reusable build logic lives in zig/ (like CMake's cmake/ modules). The target
// definitions live in each directory's build.zig (like a per-directory
// CMakeLists.txt); build.zig only builds the shared context and descends.
const targets = @import("zig/target.zig");
const vcpkg = @import("zig/vcpkg.zig");
const android = @import("zig/android.zig");
const emscripten = @import("zig/emscripten.zig");
const Ctx = @import("zig/Ctx.zig").Ctx;

const src = @import("app/briarthorn/src/build.zig");

pub fn build(b: *std.Build) void {
    var target = b.standardTargetOptions(.{});
    // Default to an optimized release build so a plain `zig build` / `zig build
    // run` just works for someone who only wants to play; developers can still
    // pass -Doptimize=Debug (or ReleaseSafe/ReleaseSmall).
    const optimize = b.option(
        std.builtin.OptimizeMode,
        "optimize",
        "optimization mode (default ReleaseFast)",
    ) orelse .ReleaseFast;

    const platform = targets.classify(target.result);

    // Zig cross-compiles to any desktop target, and the zig overlay triplets
    // build the vcpkg dependencies with zig too — but the target platform's
    // system pieces still have to be present on the build machine (X11 headers
    // and libraries on linux, the platform SDK on macos). So desktop targets
    // require a matching host; only android and wasm are cross-compiled.
    // Fail here with an explanation instead of deep in vcpkg.
    switch (platform) {
        .windows, .linux, .macos => if (target.result.os.tag != b.graph.host.result.os.tag)
            std.process.fatal("cannot build the {s} desktop target on a {s} host: the dependencies " ++
                "need {s} system libraries (e.g. X11) that only exist on a {s} build machine. " ++
                "Build on a matching host (the devcontainer or WSL covers linux); android and " ++
                "wasm targets do cross-compile from any host.", .{
                @tagName(target.result.os.tag),
                @tagName(b.graph.host.result.os.tag),
                @tagName(target.result.os.tag),
                @tagName(target.result.os.tag),
            }),
        .android, .emscripten => {},
    }

    // Android needs a concrete API level to pick bionic CRT objects; fold it
    // into the target so __ANDROID_API__ matches what we link against.
    const android_api = b.option(u32, "android-api", "Android API level (android targets only)") orelse 35;
    if (platform == .android and target.query.android_api_level == null) {
        var query = target.query;
        query.android_api_level = android_api;
        target = b.resolveTargetQuery(query);
    }

    const triplet_override = b.option([]const u8, "vcpkg-triplet", "Override the vcpkg target triplet");
    if (triplet_override) |t|
        std.debug.print("note: vcpkg triplet overridden to {s}; you are responsible for ABI compatibility\n", .{t});
    const triplet = triplet_override orelse targets.vcpkgTriplet(platform, target.result);
    const host_triplet = targets.vcpkgHostTriplet(b);

    // Mirror the CMake preset layout: everything for one target lives under
    // build/<target>/ — vcpkg packages in vcpkg_installed/, final binaries in
    // installed/. vcpkg manifest mode syncs an install root to a single
    // triplet and evicts any other triplet's packages, so the per-target root
    // also keeps switching between `zig build` targets cheap.
    const target_dir = b.fmt("build/{s}", .{targets.dirName(b, platform, target.result, optimize)});
    const vcpkg_root = b.fmt("{s}/vcpkg_installed", .{target_dir});
    const install_prefix = b.fmt("{s}/installed", .{target_dir});

    vcpkg.ensureInstalled(b, platform, triplet, host_triplet, vcpkg_root);

    const installed = b.fmt("{s}/{s}", .{ vcpkg_root, triplet });
    const include_rel = b.fmt("{s}/include", .{installed});
    const lib_rel = if (optimize == .Debug)
        b.fmt("{s}/debug/lib", .{installed})
    else
        b.fmt("{s}/lib", .{installed});

    // The android NDK / emsdk env scans below are host observations the
    // configure cache cannot track; a cached configuration would bake stale
    // absolute SDK paths.
    if (platform == .android or platform == .emscripten) b.graph.poisonCache();

    const ctx: Ctx = .{
        .b = b,
        .target = target,
        .optimize = optimize,
        .platform = platform,
        .include_rel = include_rel,
        .lib_rel = lib_rel,
        .install_prefix = install_prefix,
        .target_dir = target_dir,
        .android = if (platform == .android) android.computeEnv(b, target, android_api) else null,
        .em_include = if (platform == .emscripten) emscripten.sysrootInclude(b) else null,
    };

    src.configure(&ctx);
}
