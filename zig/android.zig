//! Android: computes the NDK toolchain env for the build context, and finishes
//! the app as a NativeActivity shared library packaged into an APK.

const std = @import("std");

const util = @import("util.zig");
const config = @import("config.zig");
const CtxMod = @import("Ctx.zig");
const Ctx = CtxMod.Ctx;
const AndroidEnv = CtxMod.AndroidEnv;

/// Computes the NDK toolchain paths and libc file for `target`. Stored in the
/// Ctx and applied to every module compiled for android (Ctx.module/applyLibC).
pub fn computeEnv(b: *std.Build, target: std.Build.ResolvedTarget, default_api: u32) AndroidEnv {
    const ndk = b.graph.environ_map.get("ANDROID_NDK_HOME") orelse
        std.process.fatal("ANDROID_NDK_HOME must point at an Android NDK for android targets", .{});
    const host_tag: []const u8 = switch (b.graph.host.result.os.tag) {
        .windows => "windows-x86_64",
        .linux => "linux-x86_64",
        .macos => "darwin-x86_64",
        else => std.process.fatal("unsupported host for android builds", .{}),
    };
    const arch_name: []const u8 = switch (target.result.cpu.arch) {
        .aarch64 => "aarch64-linux-android",
        .x86_64 => "x86_64-linux-android",
        else => unreachable, // filtered by vcpkgTriplet
    };
    const api = target.query.android_api_level orelse default_api;

    const prebuilt = b.pathJoin(&.{ ndk, "toolchains", "llvm", "prebuilt", host_tag });
    const sys_include = b.pathJoin(&.{ prebuilt, "sysroot", "usr", "include" });
    const lib_unversioned = b.pathJoin(&.{ prebuilt, "sysroot", "usr", "lib", arch_name });
    const crt_dir = b.pathJoin(&.{ lib_unversioned, b.fmt("{d}", .{api}) });

    // Zig does not ship bionic; describe the NDK's libc with a libc file.
    const write_files = b.addWriteFiles();
    const libc_file = write_files.add("android-libc.txt", b.fmt(
        \\include_dir={s}
        \\sys_include_dir={s}
        \\crt_dir={s}
        \\msvc_lib_dir=
        \\kernel32_lib_dir=
        \\gcc_dir=
        \\
    , .{ sys_include, b.pathJoin(&.{ sys_include, arch_name }), crt_dir }));

    // vcpkg's raylib declares `-Wl,--wrap=fopen` in its usage requirements so
    // that fopen() routes reads through the APK asset manager (__wrap_fopen)
    // and writes into the app data dir. Zig's linker step cannot pass --wrap,
    // so emulate it: a hidden fopen definition intercepts the statically
    // linked objects' fopen calls (the same set --wrap would rewrite), and
    // __real_fopen reaches bionic's fopen through its fopen64 alias.
    const fopen_shim = write_files.add("android-fopen-wrap.c",
        \\// FILE is only used as an opaque pointer; no headers needed.
        \\typedef struct FILE FILE;
        \\FILE *__wrap_fopen(const char *path, const char *mode);
        \\FILE *fopen64(const char *path, const char *mode);
        \\
        \\__attribute__((visibility("hidden"))) FILE *fopen(const char *path, const char *mode)
        \\{
        \\    return __wrap_fopen(path, mode);
        \\}
        \\
        \\__attribute__((visibility("hidden"))) FILE *__real_fopen(const char *path, const char *mode)
        \\{
        \\    return fopen64(path, mode);
        \\}
        \\
    );

    return .{
        .ndk = ndk,
        .prebuilt = prebuilt,
        .sys_include = sys_include,
        .lib_unversioned = lib_unversioned,
        .crt_dir = crt_dir,
        .arch_name = arch_name,
        .api = api,
        .libc_file = libc_file,
        // NDK libc++ headers replace zig's bundled ones (see Ctx.module).
        .libcxx_include = b.graph.cwdRelativePath(b.pathJoin(&.{ sys_include, "c++", "v1" })),
        .fopen_shim = fopen_shim,
    };
}

/// Finishes the app: links the app module (main.cpp + the fopen shim) and the
/// graphics-edge archive (which pulls the game core in transitively) into a
/// NativeActivity shared library, then packages it into an APK with the gradle
/// project in android/.
pub fn finishApp(c: *const Ctx, app_mod: *std.Build.Module, graphics: *std.Build.Step.Compile) void {
    const b = c.b;
    const a = c.android.?;

    // The --wrap=fopen shim intercepts fopen for the whole binary, so it lives
    // on the final module, not the library.
    app_mod.addCSourceFile(.{ .file = a.fopen_shim, .language = .c });

    // target_link_libraries(app PRIVATE briarthorn-raylib), before raylib below:
    // app -> raylib edge -> game core (transitive), then raylib.a.
    app_mod.linkLibrary(graphics);

    app_mod.addLibraryPath(b.graph.cwdRelativePath(a.crt_dir));
    app_mod.addLibraryPath(b.graph.cwdRelativePath(a.lib_unversioned));

    // raylib is a NativeActivity app: it provides ANativeActivity_onCreate and
    // android_main, and calls the app's regular main().
    app_mod.addObjectFile(b.path(b.pathJoin(&.{ c.lib_rel, "libraylib.a" })));
    app_mod.addObjectFile(b.graph.cwdRelativePath(b.pathJoin(&.{ a.lib_unversioned, "libc++_static.a" })));
    app_mod.addObjectFile(b.graph.cwdRelativePath(b.pathJoin(&.{ a.lib_unversioned, "libc++abi.a" })));
    if (clangRuntimeLibDir(b, a.prebuilt, c.target.result.cpu.arch)) |dir| {
        app_mod.addLibraryPath(b.graph.cwdRelativePath(dir));
        app_mod.linkSystemLibrary("unwind", .{ .use_pkg_config = .no });
    }
    const android_libs = [_][]const u8{ "log", "android", "GLESv2", "EGL", "OpenSLES" };
    for (android_libs) |name| app_mod.linkSystemLibrary(name, .{ .use_pkg_config = .no });

    const lib = b.addLibrary(.{
        .linkage = .dynamic,
        .name = config.app_name,
        .root_module = app_mod,
    });
    lib.setLibCFile(a.libc_file);
    a.libc_file.addStepDependencies(&lib.step);
    // NativeActivity looks the entry point up in the shared library; force it
    // to be pulled out of the static raylib archive.
    lib.forceUndefinedSymbol("ANativeActivity_onCreate");
    lib.use_llvm = true;
    lib.use_lld = true;
    // Provides the __aarch64_* outline atomics the NDK expects from compiler-rt.
    lib.bundle_compiler_rt = true;
    // Android 15+ requires 16 KiB page alignment.
    lib.link_z_max_page_size = 16384;

    const install_files = b.addUpdateSourceFiles();
    util.installFile(b, install_files, lib.getEmittedBin(), c.install_prefix, "lib", lib.out_filename);
    b.getInstallStep().dependOn(&install_files.step);

    // Package the library into an APK with the gradle project in android/.
    // The -PzigJniLibs property makes gradle package the staged zig-built
    // library instead of running its own CMake externalNativeBuild.
    ensureSdkConfigured(b, a.ndk);
    const abi: []const u8 = switch (c.target.result.cpu.arch) {
        .aarch64 => "arm64-v8a",
        .x86_64 => "x86_64",
        else => unreachable, // filtered by vcpkgTriplet
    };
    const jni_dir = b.fmt("{s}/jniLibs", .{c.target_dir});
    const jni_stage = b.addUpdateSourceFiles();
    jni_stage.addCopyFileToSource(
        lib.getEmittedBin(),
        b.fmt("{s}/{s}/{s}", .{ jni_dir, abi, lib.out_filename }),
    );

    const root = util.rootPath(b);
    const host_is_windows = b.graph.host.result.os.tag == .windows;
    const gradlew = b.pathJoin(&.{ root, "android", if (host_is_windows) "gradlew.bat" else "gradlew" });
    const gradle = if (host_is_windows)
        b.addSystemCommand(&.{gradlew})
    else
        b.addSystemCommand(&.{ "sh", gradlew });
    gradle.addArgs(&.{ "-p", b.pathJoin(&.{ root, "android" }) });
    gradle.addArg(if (c.optimize == .Debug) "assembleDebug" else "assembleRelease");
    gradle.addArg(b.fmt("-PzigJniLibs={s}", .{b.pathResolve(&.{ root, jni_dir })}));
    gradle.step.dependOn(&jni_stage.step);
    // Gradle writes into android/app/build, which zig cannot track.
    gradle.has_side_effects = true;

    const kind: []const u8 = if (c.optimize == .Debug) "debug" else "release";
    const apk_name = b.fmt("app-{s}.apk", .{kind});
    const apk_install = b.addUpdateSourceFiles();
    apk_install.addCopyFileToSource(
        b.path(b.fmt("android/app/build/outputs/apk/{s}/{s}", .{ kind, apk_name })),
        b.fmt("{s}/apk/{s}", .{ c.install_prefix, apk_name }),
    );
    apk_install.step.dependOn(&gradle.step);
    b.getInstallStep().dependOn(&apk_install.step);
}

/// Gradle locates the Android SDK through android/local.properties, which is
/// machine-specific and gitignored. If it is missing or points at a directory
/// that does not exist on this machine (e.g. a devcontainer path), regenerate
/// it from the environment.
fn ensureSdkConfigured(b: *std.Build, ndk: []const u8) void {
    const io = b.graph.io;
    const cwd = std.Io.Dir.cwd();
    const root = util.rootPath(b);
    const props_path = b.pathJoin(&.{ root, "android", "local.properties" });

    if (cwd.readFileAlloc(io, props_path, b.allocator, .unlimited)) |contents| {
        if (sdkDirFromProperties(contents)) |sdk_dir| {
            if (cwd.access(io, sdk_dir, .{})) |_| return else |_| {}
        }
    } else |_| {}

    const env = &b.graph.environ_map;
    const derived: ?[]const u8 = blk: {
        // <sdk>/ndk/<version> is the SDK-managed NDK layout.
        const ndk_parent = std.fs.path.dirname(ndk) orelse break :blk null;
        if (!std.mem.eql(u8, std.fs.path.basename(ndk_parent), "ndk")) break :blk null;
        break :blk std.fs.path.dirname(ndk_parent);
    };
    const sdk = env.get("ANDROID_HOME") orelse env.get("ANDROID_SDK_ROOT") orelse derived orelse
        std.process.fatal("cannot determine the Android SDK location for gradle: set ANDROID_HOME " ++
            "or write android/local.properties with sdk.dir=", .{});
    cwd.access(io, sdk, .{}) catch
        std.process.fatal("Android SDK not found at '{s}'", .{sdk});

    // Forward slashes: backslashes are escape characters in .properties files.
    const sdk_fwd = b.allocator.dupe(u8, sdk) catch @panic("OOM");
    std.mem.replaceScalar(u8, sdk_fwd, '\\', '/');
    cwd.writeFile(io, .{
        .sub_path = props_path,
        .data = b.fmt("# This file is automatically generated. Do not commit to version control.\nsdk.dir={s}\n", .{sdk_fwd}),
    }) catch |err|
        std.process.fatal("unable to write android/local.properties: {s}", .{@errorName(err)});
}

fn sdkDirFromProperties(contents: []const u8) ?[]const u8 {
    var it = std.mem.splitScalar(u8, contents, '\n');
    while (it.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (std.mem.startsWith(u8, line, "sdk.dir=")) return line["sdk.dir=".len..];
    }
    return null;
}

/// The NDK's libunwind.a lives in the clang resource directory, whose path
/// contains the clang major version; find it instead of hard-coding it.
fn clangRuntimeLibDir(b: *std.Build, prebuilt: []const u8, arch: std.Target.Cpu.Arch) ?[]const u8 {
    const io = b.graph.io;
    const clang_root = b.pathJoin(&.{ prebuilt, "lib", "clang" });
    var dir = std.Io.Dir.cwd().openDir(io, clang_root, .{ .iterate = true }) catch return null;
    defer dir.close(io);
    var it = dir.iterate();
    while (it.next(io) catch null) |entry| {
        if (entry.kind != .directory) continue;
        const candidate = b.pathJoin(&.{ clang_root, entry.name, "lib", "linux", @tagName(arch) });
        std.Io.Dir.cwd().access(io, candidate, .{}) catch continue;
        return candidate;
    }
    return null;
}
