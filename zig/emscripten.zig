//! Emscripten/wasm: resolves the emsdk sysroot for the build context, and
//! finishes the app by compiling it to a static library and handing the final
//! link to emcc (which supplies GLFW/GL/libc/libc++ and emits .html/.js/.wasm).
//! Also exposes resolveRoot, which vcpkg's wasm32-emscripten triplet needs at
//! install time.

const std = @import("std");

const util = @import("util.zig");
const config = @import("config.zig");
const Ctx = @import("Ctx.zig").Ctx;

/// The emsdk sysroot include path, stored in the Ctx and added to every module
/// compiled for wasm (Zig has no libc headers for emscripten).
pub fn sysrootInclude(b: *std.Build) std.Build.LazyPath {
    const em_root = resolveRoot(b);
    return b.graph.cwdRelativePath(b.pathJoin(&.{ em_root, "cache", "sysroot", "include" }));
}

/// Finishes the app: compiles the app module (main.cpp) to a static library and
/// links it with the graphics-edge archive, the game-core archive, and raylib
/// via emcc into the .html/.js/.wasm triple.
pub fn finishApp(c: *const Ctx, app_mod: *std.Build.Module, game: *std.Build.Step.Compile, graphics: *std.Build.Step.Compile) void {
    const b = c.b;
    const em_root = resolveRoot(b);

    // Zig cannot drive the emscripten linker, so compile the app to a static
    // library and let emcc do the final link (it supplies the GLFW/GL/libc/libc++
    // implementations and emits the .html/.js/.wasm triple). The emsdk sysroot
    // include was already added to app_mod by Ctx.module.
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = config.app_name,
        .root_module = app_mod,
    });

    const emcc = b.addSystemCommand(&.{emccExecutable(b, em_root)});
    const opt_flags: []const []const u8 = switch (c.optimize) {
        .Debug => &.{ "-O0", "-g", "-sASSERTIONS=1" },
        .ReleaseSmall => &.{"-Oz"},
        else => &.{"-O3"},
    };
    emcc.addArgs(opt_flags);
    emcc.addArgs(&.{ "-sUSE_GLFW=3", "-sASYNCIFY" });
    // Custom HTML shell that carries the app icon as the browser-tab favicon.
    // addFileArg registers it as an input so a shell edit re-runs emcc.
    emcc.addArg("--shell-file");
    emcc.addFileArg(b.path("app/briarthorn/web/shell.html"));
    // app.a -> briarthorn-raylib.a -> briarthorn-game.a -> raylib.a: each
    // references symbols in the next (the single-pass link order emcc needs).
    emcc.addArtifactArg(lib);
    emcc.addArtifactArg(graphics);
    emcc.addArtifactArg(game);
    emcc.addFileArg(b.path(b.pathJoin(&.{ c.lib_rel, "libraylib.a" })));
    emcc.addArg("-o");
    const html = emcc.addOutputFileArg(config.app_name ++ ".html");

    // emcc emits the .js and .wasm next to the requested .html output.
    const install_files = b.addUpdateSourceFiles();
    util.installFile(b, install_files, html, c.install_prefix, "web", config.app_name ++ ".html");
    util.installFile(b, install_files, outputSibling(html, config.app_name ++ ".js"), c.install_prefix, "web", config.app_name ++ ".js");
    util.installFile(b, install_files, outputSibling(html, config.app_name ++ ".wasm"), c.install_prefix, "web", config.app_name ++ ".wasm");
    b.getInstallStep().dependOn(&install_files.step);
}

/// References a file emitted into the same generated directory as `output`
/// (an addOutputFileArg result) without being named on the command line.
fn outputSibling(output: std.Build.LazyPath, basename: []const u8) std.Build.LazyPath {
    return .{ .generated = .{
        .index = output.generated.index,
        .up = output.generated.up + 1,
        .sub_path = basename,
    } };
}

const EmscriptenRoot = struct { path: []const u8, source: []const u8 };

fn findRoot(b: *std.Build) ?EmscriptenRoot {
    const env = &b.graph.environ_map;
    if (env.get("EMSCRIPTEN_ROOT")) |root| return .{ .path = root, .source = "EMSCRIPTEN_ROOT" };
    if (env.get("EMSDK")) |emsdk| return .{
        .path = b.pathJoin(&.{ emsdk, "upstream", "emscripten" }),
        .source = "EMSDK",
    };
    if (b.findProgram(.{ .names = &.{"emcc"} })) |emcc| {
        if (std.fs.path.dirname(emcc)) |dir| return .{ .path = dir, .source = "PATH" };
    }
    return null;
}

/// Resolves an emscripten installation, verifying emcc is actually present so
/// a broken setup fails fast instead of deep inside vcpkg. When no environment
/// override is set, falls back to a per-host prefix under .emsdk/,
/// bootstrapping it from the emsdk submodule on first use (like the vcpkg
/// submodule). Installs are keyed by host OS because the toolchain binaries
/// are platform-specific: one working tree may be shared across operating
/// systems (WSL, devcontainers), and a single shared install would be
/// clobbered on every switch.
pub fn resolveRoot(b: *std.Build) []const u8 {
    const io = b.graph.io;
    const cwd = std.Io.Dir.cwd();

    if (findRoot(b)) |found| {
        const emcc = emccExecutable(b, found.path);
        cwd.access(io, emcc, .{}) catch
            std.process.fatal("emcc not found at '{s}' (from {s}); run 'emsdk install latest && " ++
                "emsdk activate latest', or fix the environment variable", .{ emcc, found.source });
        return found.path;
    }

    const root = util.rootPath(b);
    const host_is_windows = b.graph.host.result.os.tag == .windows;
    // Spelled like CMake's ${hostSystemName} so the CMake presets address the
    // same directory without a mapping layer.
    const host_key: []const u8 = switch (b.graph.host.result.os.tag) {
        .windows => "Windows",
        .macos => "Darwin",
        else => "Linux",
    };
    const install_dir = b.pathJoin(&.{ root, ".emsdk", host_key });
    const em_root = b.pathJoin(&.{ install_dir, "upstream", "emscripten" });
    // Require the activate-written config too, so an interrupted bootstrap
    // (installed but never activated) is retried instead of trusted.
    if (cwd.access(io, emccExecutable(b, em_root), .{})) |_| {
        if (cwd.access(io, b.pathJoin(&.{ install_dir, ".emscripten" }), .{})) |_| return em_root else |_| {}
    } else |_| {}

    const emsdk_dir = b.pathJoin(&.{ root, "emsdk" });
    const script_name = if (host_is_windows) "emsdk.bat" else "emsdk";
    if (cwd.access(io, b.pathJoin(&.{ emsdk_dir, script_name }), .{})) |_| {} else |_| std.process.fatal("emscripten not found: initialize the emsdk submodule " ++
        "(git submodule update --init), or set EMSDK/EMSCRIPTEN_ROOT, or put emcc on PATH", .{});

    // We are about to mutate the install prefix; never cache this configure run.
    b.graph.poisonCache();
    std.debug.print("bootstrapping emscripten into {s} (one-time toolchain download)...\n", .{install_dir});

    // emsdk installs into whatever directory its scripts run from, so copy
    // the installer files out of the (pristine) submodule into the per-host
    // prefix and run them there. scripts/bootstrap-emsdk.sh mirrors this.
    cwd.createDirPath(io, install_dir) catch |err|
        std.process.fatal("unable to create {s}: {s}", .{ install_dir, @errorName(err) });
    var src_dir = cwd.openDir(io, emsdk_dir, .{ .iterate = true }) catch |err|
        std.process.fatal("unable to open {s}: {s}", .{ emsdk_dir, @errorName(err) });
    defer src_dir.close(io);
    var dst_dir = cwd.openDir(io, install_dir, .{}) catch |err|
        std.process.fatal("unable to open {s}: {s}", .{ install_dir, @errorName(err) });
    defer dst_dir.close(io);
    var it = src_dir.iterate();
    while (it.next(io) catch null) |entry| {
        if (entry.kind != .file) continue;
        std.Io.Dir.copyFile(src_dir, entry.name, dst_dir, entry.name, io, .{}) catch |err|
            std.process.fatal("unable to copy emsdk installer file {s}: {s}", .{ entry.name, @errorName(err) });
    }

    // "latest" resolves against the release list checked into the pinned
    // submodule commit, so the submodule pin determines the toolchain version.
    const emsdk_script = b.pathJoin(&.{ install_dir, script_name });
    if (host_is_windows) {
        util.runChecked(b, &.{ emsdk_script, "install", "latest" }, root, null);
        util.runChecked(b, &.{ emsdk_script, "activate", "latest" }, root, null);
    } else {
        util.runChecked(b, &.{ "sh", emsdk_script, "install", "latest" }, root, null);
        util.runChecked(b, &.{ "sh", emsdk_script, "activate", "latest" }, root, null);
    }
    // Re-probe: the emcc file name (emcc.bat/emcc.exe/emcc) is only knowable
    // now that the toolchain exists.
    const emcc = emccExecutable(b, em_root);
    cwd.access(io, emcc, .{}) catch
        std.process.fatal("emsdk bootstrap did not produce {s}", .{emcc});
    return em_root;
}

fn emccExecutable(b: *std.Build, em_root: []const u8) []const u8 {
    const io = b.graph.io;
    if (b.graph.host.result.os.tag == .windows) {
        for ([_][]const u8{ "emcc.bat", "emcc.exe" }) |name| {
            const path = b.pathJoin(&.{ em_root, name });
            if (std.Io.Dir.cwd().access(io, path, .{})) |_| return path else |_| {}
        }
    }
    return b.pathJoin(&.{ em_root, "emcc" });
}
