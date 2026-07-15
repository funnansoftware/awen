//! vcpkg dependency install, run at configure time. Bootstraps vcpkg if
//! needed, installs the manifest for the target triplet, and uses a
//! content-keyed stamp so warm builds are a cheap no-op.

const std = @import("std");

const Platform = @import("target.zig").Platform;
const util = @import("util.zig");
const emscripten = @import("emscripten.zig");

/// Installs the manifest dependencies for `triplet` into `install_root`,
/// bootstrapping vcpkg first if needed. A stamp file keyed on the manifest
/// contents makes this a cheap no-op on subsequent builds.
pub fn ensureInstalled(
    b: *std.Build,
    platform: Platform,
    triplet: []const u8,
    host_triplet: []const u8,
    install_root: []const u8,
) void {
    const io = b.graph.io;
    const cwd = std.Io.Dir.cwd();
    const host_is_windows = b.graph.host.result.os.tag == .windows;

    // Re-run the configure phase when the manifests or the stamp change. The
    // stamp lives inside the install root so deleting that root (or the whole
    // build/<target> dir) also deletes the stamp, which retriggers configure
    // even on a warm cache.
    const stamp_rel = b.fmt("{s}/.zig-stamp", .{install_root});
    b.dependOnFileContents(b.path("vcpkg.json"));
    b.dependOnFileContents(b.path(stamp_rel));

    const root = util.rootPath(b);
    const manifest = cwd.readFileAlloc(io, b.pathJoin(&.{ root, "vcpkg.json" }), b.allocator, .unlimited) catch |err|
        std.process.fatal("unable to read vcpkg.json: {s}", .{@errorName(err)});
    const config = cwd.readFileAlloc(io, b.pathJoin(&.{ root, "vcpkg-configuration.json" }), b.allocator, .unlimited) catch |err| blk: {
        // The overlay triplet that builds windows ports with zig is declared
        // there; without it vcpkg would silently fall back to the community
        // x64-mingw-static triplet and produce ABI-mismatched libraries.
        if (std.mem.eql(u8, triplet, "x64-mingw-static"))
            std.process.fatal("unable to read vcpkg-configuration.json (declares the zig overlay triplet): {s}", .{@errorName(err)});
        b.graph.poisonCache();
        break :blk "";
    };
    if (config.len != 0) b.dependOnFileContents(b.path("vcpkg-configuration.json"));

    var hasher = std.crypto.hash.sha2.Sha256.init(.{});
    hasher.update(install_root);
    hasher.update(&.{0});
    hasher.update(triplet);
    hasher.update(&.{0});
    hasher.update(manifest);
    hasher.update(&.{0});
    hasher.update(config);
    // The overlay triplets and the toolchain files they chainload feed vcpkg's
    // ABI hashes; editing them must invalidate the stamp or the app would
    // silently keep linking libraries built with the old settings.
    hashToolchainInputs(b, &hasher);
    var digest: [32]u8 = undefined;
    hasher.final(&digest);
    const want = std.fmt.bytesToHex(digest, .lower);

    const stamp_path = b.pathJoin(&.{ root, stamp_rel });
    const installed_include = b.pathJoin(&.{ root, install_root, triplet, "include" });
    if (cwd.readFileAlloc(io, stamp_path, b.allocator, .unlimited)) |have| {
        if (std.mem.eql(u8, have, &want)) {
            // Guard against a stale stamp when the installed tree was removed.
            if (cwd.access(io, installed_include, .{})) |_| return else |_| {}
        }
    } else |_| {}

    // The zig compiler wrappers used by the overlay triplets resolve `zig`
    // from PATH; guarantee the vcpkg child sees the same zig running this
    // build, wherever it is installed.
    var vcpkg_env = b.graph.environ_map.clone(b.allocator) catch @panic("OOM");
    if (std.fs.path.dirname(b.graph.zig_exe)) |zig_dir| {
        const old_path = vcpkg_env.get("PATH") orelse "";
        vcpkg_env.put("PATH", b.fmt("{s}{c}{s}", .{
            zig_dir, std.fs.path.delimiter, old_path,
        })) catch @panic("OOM");
    }

    // Fail early, before a long vcpkg run, if a required SDK is missing.
    switch (platform) {
        .android => if (b.graph.environ_map.get("ANDROID_NDK_HOME") == null)
            std.process.fatal("ANDROID_NDK_HOME must point at an Android NDK to install the {s} triplet", .{triplet}),
        .emscripten => {
            // vcpkg's wasm32-emscripten triplet locates the toolchain through
            // this env var; point it at whichever emscripten was resolved
            // (possibly the just-bootstrapped per-host prefix under .emsdk/).
            const em_root = emscripten.resolveRoot(b);
            vcpkg_env.put("EMSCRIPTEN_ROOT", em_root) catch @panic("OOM");
        },
        else => {},
    }

    // We are about to mutate vcpkg_installed/; never cache this configure run.
    b.graph.poisonCache();

    const vcpkg_exe = b.pathJoin(&.{ root, "vcpkg", if (host_is_windows) "vcpkg.exe" else "vcpkg" });
    if (cwd.access(io, vcpkg_exe, .{})) |_| {} else |_| {
        const bootstrap = b.pathJoin(&.{
            root, "vcpkg", if (host_is_windows) "bootstrap-vcpkg.bat" else "bootstrap-vcpkg.sh",
        });
        if (cwd.access(io, bootstrap, .{})) |_| {} else |_| std.process.fatal("vcpkg submodule is missing or empty; run: git submodule update --init", .{});
        std.debug.print("bootstrapping vcpkg...\n", .{});
        // Spawn the .bat directly: zig serializes it through the mitigated
        // cmd.exe form, which survives paths containing cmd metacharacters.
        if (host_is_windows) {
            util.runChecked(b, &.{ bootstrap, "-disableMetrics" }, root, null);
        } else {
            util.runChecked(b, &.{ "sh", bootstrap, "-disableMetrics" }, root, null);
        }
        if (cwd.access(io, vcpkg_exe, .{})) |_| {} else |_| std.process.fatal("vcpkg bootstrap did not produce {s}", .{vcpkg_exe});
    }

    std.debug.print("installing vcpkg dependencies for {s} (host {s})...\n", .{ triplet, host_triplet });
    // cwd = manifest root: vcpkg picks up vcpkg.json and the overlay triplets
    // declared in vcpkg-configuration.json, and resolves the install root
    // relative to it.
    util.runChecked(b, &.{
        vcpkg_exe,
        "install",
        b.fmt("--triplet={s}", .{triplet}),
        b.fmt("--host-triplet={s}", .{host_triplet}),
        b.fmt("--x-install-root={s}", .{install_root}),
    }, root, &vcpkg_env);

    cwd.createDirPath(io, b.pathJoin(&.{ root, install_root })) catch {};
    cwd.writeFile(io, .{ .sub_path = stamp_path, .data = &want }) catch |err|
        std.process.fatal("unable to write vcpkg stamp: {s}", .{@errorName(err)});
}

/// Feeds the overlay triplets, the toolchain files they chainload, and the
/// zig compiler wrappers into the stamp hash, and registers them as configure
/// dependencies so edits retrigger both the configure phase and vcpkg install.
fn hashToolchainInputs(b: *std.Build, hasher: *std.crypto.hash.sha2.Sha256) void {
    const io = b.graph.io;
    const cwd = std.Io.Dir.cwd();
    const root = util.rootPath(b);
    const dirs = [_][]const u8{ "cmake/triplets", "cmake/toolchain", "scripts" };
    for (dirs) |rel_dir| {
        var dir = cwd.openDir(io, b.pathJoin(&.{ root, rel_dir }), .{ .iterate = true }) catch continue;
        defer dir.close(io);
        b.dependOnDirectory(b.path(rel_dir));

        var names: std.ArrayList([]const u8) = .empty;
        var it = dir.iterate();
        while (it.next(io) catch null) |entry| {
            if (entry.kind != .file) continue;
            names.append(b.allocator, b.dupe(entry.name)) catch @panic("OOM");
        }
        std.mem.sort([]const u8, names.items, {}, struct {
            fn lessThan(_: void, lhs: []const u8, rhs: []const u8) bool {
                return std.mem.lessThan(u8, lhs, rhs);
            }
        }.lessThan);

        for (names.items) |name| {
            const rel = b.pathJoin(&.{ rel_dir, name });
            b.dependOnFileContents(b.path(rel));
            const contents = cwd.readFileAlloc(io, b.pathJoin(&.{ root, rel }), b.allocator, .unlimited) catch continue;
            hasher.update(name);
            hasher.update(&.{0});
            hasher.update(contents);
            hasher.update(&.{0});
        }
    }
}
