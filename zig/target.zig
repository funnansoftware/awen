//! Target classification and vcpkg triplet mapping.

const std = @import("std");

pub const Platform = enum { windows, linux, macos, android, emscripten };

pub fn classify(t: std.Target) Platform {
    if (t.os.tag == .emscripten) return .emscripten;
    if (t.abi.isAndroid()) return .android;
    return switch (t.os.tag) {
        .windows => .windows,
        .linux => .linux,
        .macos => .macos,
        else => std.process.fatal("unsupported target os: {s}", .{@tagName(t.os.tag)}),
    };
}

/// Directory name under build/ for a target+optimize combination, mirroring
/// the CMake preset layout: the resolved arch-os-abi triple plus the optimize
/// mode (e.g. build/aarch64-linux-android-debug), so builds with different
/// optimize modes never overwrite each other.
pub fn dirName(
    b: *std.Build,
    platform: Platform,
    t: std.Target,
    optimize: std.builtin.OptimizeMode,
) []const u8 {
    const mode = b.allocator.dupe(u8, @tagName(optimize)) catch @panic("OOM");
    _ = std.ascii.lowerString(mode, mode);
    if (platform == .emscripten)
        return b.fmt("{s}-emscripten-{s}", .{ @tagName(t.cpu.arch), mode });
    if (t.abi == .none)
        return b.fmt("{s}-{s}-{s}", .{ @tagName(t.cpu.arch), @tagName(t.os.tag), mode });
    return b.fmt("{s}-{s}-{s}-{s}", .{ @tagName(t.cpu.arch), @tagName(t.os.tag), @tagName(t.abi), mode });
}

pub fn vcpkgTriplet(platform: Platform, t: std.Target) []const u8 {
    return switch (platform) {
        .windows => switch (t.cpu.arch) {
            // The overlay triplet in cmake/triplets builds ports with zig
            // targeting x86_64-windows-gnu, matching zig's own windows ABI.
            .x86_64 => if (t.abi == .msvc)
                std.process.fatal("the msvc abi is not supported by zig build; use the default " ++
                    "gnu abi (or the CMake msvc presets)", .{})
            else
                "x64-mingw-static",
            else => unsupportedArch(t),
        },
        // The "-zig" overlay triplets in cmake/triplets build ports with zig
        // (chainloaded toolchain), so a `zig build` compiles its dependencies
        // with the same compiler as the app. They are named distinctly from the
        // stock triplets so the native CMake presets are unaffected.
        .linux => switch (t.cpu.arch) {
            .x86_64 => "x64-linux-zig",
            .aarch64 => "arm64-linux-zig",
            else => unsupportedArch(t),
        },
        .macos => switch (t.cpu.arch) {
            .aarch64 => "arm64-osx-zig",
            .x86_64 => "x64-osx-zig",
            else => unsupportedArch(t),
        },
        .android => switch (t.cpu.arch) {
            .aarch64 => "arm64-android",
            .x86_64 => "x64-android",
            else => unsupportedArch(t),
        },
        .emscripten => "wasm32-emscripten",
    };
}

fn unsupportedArch(t: std.Target) noreturn {
    std.process.fatal("unsupported cpu arch {s} for os {s}", .{
        @tagName(t.cpu.arch), @tagName(t.os.tag),
    });
}

pub fn vcpkgHostTriplet(b: *std.Build) []const u8 {
    const host = b.graph.host.result;
    const arm = host.cpu.arch == .aarch64;
    return switch (host.os.tag) {
        .windows => if (arm) "arm64-windows" else "x64-windows",
        .linux => if (arm) "arm64-linux" else "x64-linux",
        .macos => if (arm) "arm64-osx" else "x64-osx",
        else => std.process.fatal("unsupported host os: {s}", .{@tagName(host.os.tag)}),
    };
}
