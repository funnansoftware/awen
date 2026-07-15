//! Build-wide constants shared across the per-platform logic in zig/.
//! The C++ source *lists* live next to the files they describe — see each
//! directory's sources.zig (src/sources.zig, src/game/sources.zig).

/// Base name of the app binary (exe on desktop, .so on android, .html on wasm).
pub const app_name = "briarthorn";

/// Name of the GoogleTest binary.
pub const test_name = "briarthorn-test";

/// Flags applied to every C++ translation unit.
pub const cxx_flags = [_][]const u8{ "-std=c++23", "-Wall", "-Wextra", "-Werror", "-pedantic" };
