//! Small build helpers shared across the per-platform logic in zig/.

const std = @import("std");

/// The project root as a path string ("." when the build root resolves empty).
/// Used to build absolute paths for the vcpkg/gradle/emsdk child processes and
/// the configure-time filesystem probes.
pub fn rootPath(b: *std.Build) []const u8 {
    const s = b.root.toString(b.allocator) catch @panic("OOM");
    return if (s.len == 0) "." else s;
}

/// The install prefix is fixed to build/<target>/installed. Zig's own install
/// steps can only target the maker-side --prefix (default zig-out), so
/// installs are modeled as build-root-relative copies instead.
pub fn installFile(
    b: *std.Build,
    usf: *std.Build.Step.UpdateSourceFiles,
    src: std.Build.LazyPath,
    install_prefix: []const u8,
    sub_dir: []const u8,
    basename: []const u8,
) void {
    usf.addCopyFileToSource(src, b.fmt("{s}/{s}/{s}", .{ install_prefix, sub_dir, basename }));
}

pub fn runChecked(
    b: *std.Build,
    argv: []const []const u8,
    cwd_path: []const u8,
    environ: ?*const std.process.Environ.Map,
) void {
    const io = b.graph.io;
    var child = std.process.spawn(io, .{
        .argv = argv,
        .cwd = .{ .path = cwd_path },
        .environ_map = environ,
        // The configure runner's stdout carries its configuration protocol;
        // pump the child's output to stderr so it reaches the console instead.
        .stdout = .pipe,
    }) catch |err| std.process.fatal("unable to spawn {s}: {s}", .{ argv[0], @errorName(err) });
    if (child.stdout) |out| {
        var buf: [4096]u8 = undefined;
        while (true) {
            const n = out.readStreaming(io, &.{&buf}) catch break;
            if (n == 0) break;
            std.debug.print("{s}", .{buf[0..n]});
        }
    }
    const term = child.wait(io) catch |err|
        std.process.fatal("failed waiting for {s}: {s}", .{ argv[0], @errorName(err) });
    if (!term.success()) std.process.fatal("command failed: {s}", .{argv[0]});
}
