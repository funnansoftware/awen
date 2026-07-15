//! The shared build context: everything CMake keeps global (the toolchain file,
//! CXX flags, find_package results, install layout) bundled into one value and
//! handed to each directory's build.zig. Because Zig has no ambient project
//! state, this is how a subdirectory gets the target/optimize/include config it
//! needs to create its own module and target.

const std = @import("std");
const Platform = @import("target.zig").Platform;
const config = @import("config.zig");

/// The android NDK toolchain paths, computed once (see zig/android.zig) and
/// applied to every module compiled for android.
pub const AndroidEnv = struct {
    ndk: []const u8,
    prebuilt: []const u8,
    sys_include: []const u8,
    lib_unversioned: []const u8,
    crt_dir: []const u8,
    arch_name: []const u8,
    api: u32,
    libc_file: std.Build.LazyPath,
    libcxx_include: std.Build.LazyPath,
    fopen_shim: std.Build.LazyPath,
};

pub const Ctx = struct {
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    platform: Platform,
    include_rel: []const u8, // vcpkg headers
    lib_rel: []const u8, // vcpkg libs
    install_prefix: []const u8,
    target_dir: []const u8,
    android: ?AndroidEnv = null,
    em_include: ?std.Build.LazyPath = null,

    const vcpkg_lib: std.Build.Module.LinkSystemLibraryOptions = .{
        .use_pkg_config = .no,
        .preferred_link_mode = .static,
    };

    pub fn isDesktop(c: *const Ctx) bool {
        return switch (c.platform) {
            .windows, .linux, .macos => true,
            .android, .emscripten => false,
        };
    }

    /// A C++ module configured for the target: libc/libc++, the src/ include
    /// root (`<game/Briarthorn.hpp>`), the vcpkg include root
    /// (`<raylib.h>`, `<gtest/gtest.h>`), and any platform system includes.
    pub fn module(c: *const Ctx) *std.Build.Module {
        const b = c.b;
        const mod = b.createModule(.{
            .target = c.target,
            .optimize = c.optimize,
            // Zig's bundled libc++ cannot be used with an Android libc file
            // (ziglang/zig#23302); android links the NDK's libc++ instead.
            .link_libcpp = if (c.platform == .android) null else true,
            .link_libc = if (c.platform == .android) true else null,
            .pic = true,
        });
        mod.addIncludePath(b.path("app/briarthorn/src"));
        mod.addSystemIncludePath(b.path(c.include_rel));
        if (c.android) |a| mod.addIncludePath(a.libcxx_include); // NDK libc++ headers
        if (c.em_include) |inc| mod.addSystemIncludePath(inc); // emsdk sysroot
        // vcpkg static libs (linked by name via linkVcpkg) live here; manual-link/
        // stages gtest_main. Present on every desktop module so a final binary can
        // resolve a vcpkg lib it inherits transitively from a library it links.
        if (c.isDesktop()) {
            mod.addLibraryPath(b.path(c.lib_rel));
            mod.addLibraryPath(b.path(b.fmt("{s}/manual-link", .{c.lib_rel})));
        }
        return mod;
    }

    /// target_sources: adds C++ files from `dir` (build-root-relative), each
    /// path relative to `dir`.
    pub fn addSources(c: *const Ctx, mod: *std.Build.Module, dir: []const u8, files: []const []const u8) void {
        mod.addCSourceFiles(.{ .root = c.b.path(dir), .files = files, .flags = &config.cxx_flags });
    }

    /// Points a compile step at the android libc file so its C++ TUs find the
    /// NDK's bionic headers; a no-op off android.
    pub fn applyLibC(c: *const Ctx, compile: *std.Build.Step.Compile) void {
        if (c.android) |a| {
            compile.setLibCFile(a.libc_file);
            a.libc_file.addStepDependencies(&compile.step);
        }
    }

    /// Links a vcpkg static library by name. List the vcpkg deps you want in
    /// each module's build.zig yourself, like target_link_libraries in CMake;
    /// the vcpkg lib directories are already on the search path (see module()).
    /// Order matters for the single-pass linker: name a library before the ones
    /// it depends on (e.g. raylib before glfw3, gtest_main before gtest).
    pub fn linkVcpkg(_: *const Ctx, mod: *std.Build.Module, name: []const u8) void {
        mod.linkSystemLibrary(name, vcpkg_lib);
    }

    /// Links the desktop platform's OS system libraries — the boilerplate raylib
    /// depends on (in CMake these come transitively from find_package(raylib)).
    /// Call it wherever you link raylib. A no-op off desktop (android/emscripten
    /// link their platform libraries in finishApp).
    pub fn linkSystemLibs(c: *const Ctx, mod: *std.Build.Module) void {
        switch (c.platform) {
            .windows => {
                const win_libs = [_][]const u8{
                    "user32", "gdi32",    "winspool", "shell32",  "ole32",
                    "uuid",   "oleaut32", "comdlg32", "advapi32",
                };
                for (win_libs) |name| mod.linkSystemLibrary(name, .{ .use_pkg_config = .no });
            },
            .linux => {
                const x11_libs = [_][]const u8{ "X11", "Xrandr", "Xinerama", "Xi", "Xcursor", "Xfixes" };
                for (x11_libs) |name| mod.linkSystemLibrary(name, .{});
            },
            .macos => {
                const frameworks = [_][]const u8{
                    "OpenGL", "Cocoa", "IOKit", "CoreFoundation", "CoreVideo", "CoreAudio",
                };
                for (frameworks) |name| mod.linkFramework(name, .{});
            },
            .android, .emscripten => {},
        }
    }

    /// Installs a built binary into build/<target>/installed/<sub_dir>.
    pub fn install(c: *const Ctx, compile: *std.Build.Step.Compile, sub_dir: []const u8) void {
        const b = c.b;
        const usf = b.addUpdateSourceFiles();
        usf.addCopyFileToSource(compile.getEmittedBin(), b.fmt("{s}/{s}/{s}", .{ c.install_prefix, sub_dir, compile.out_filename }));
        // No PDB exists when debug info is stripped (zig's default for ReleaseSmall).
        if (c.platform == .windows and c.optimize != .ReleaseSmall)
            usf.addCopyFileToSource(compile.getEmittedPdb(), b.fmt("{s}/{s}/{s}.pdb", .{ c.install_prefix, sub_dir, config.app_name }));
        b.getInstallStep().dependOn(&usf.step);
    }

    /// Wires the `run` step to the given executable.
    pub fn runStep(c: *const Ctx, exe: *std.Build.Step.Compile) void {
        const b = c.b;
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());
        run_cmd.addPassthruArgs();
        b.step("run", "Run the app").dependOn(&run_cmd.step);
    }

    /// Wires the `test` step to run the given test executable.
    pub fn testStep(c: *const Ctx, exe: *std.Build.Step.Compile) void {
        const b = c.b;
        b.step("test", "Build and run the GoogleTest suite").dependOn(&b.addRunArtifact(exe).step);
    }

    /// Off desktop, `run`/`test` are unavailable; make them fail with an
    /// explanation instead of silently doing nothing.
    pub fn stubDesktopOnlySteps(c: *const Ctx) void {
        const b = c.b;
        b.step("run", "Run the app").dependOn(
            &b.addFail("the run step is only available for desktop targets").step,
        );
        b.step("test", "Build and run the GoogleTest suite").dependOn(
            &b.addFail("the test step is only available for desktop targets " ++
                "(GoogleTest is not built for android/wasm)").step,
        );
    }
};
