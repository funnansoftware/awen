#!/bin/sh
# Bootstraps the emscripten toolchain into a per-host prefix (.emsdk/<host>).
#
# The emsdk submodule stays pristine: it only supplies the installer scripts
# and the pinned release list ("latest" resolves against the list checked
# into the pinned submodule commit). Installs are keyed by host OS because
# the toolchain binaries are platform-specific: one working tree may be
# shared across operating systems (WSL, devcontainers), and a single shared
# install would be clobbered on every switch.
#
# The zig web build (build.zig) bootstraps the same layout automatically;
# this script exists for the CMake-only flow (CI and local presets). On
# Windows, use scripts/bootstrap-emsdk.bat instead.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"

# Matches CMake's ${hostSystemName} so the presets address the same directory.
host="$(uname -s)"
case "$host" in
Linux | Darwin) ;;
*)
    echo "unsupported host '$host'; on Windows run scripts/bootstrap-emsdk.bat, or bootstrap via 'zig build -Dtarget=wasm32-emscripten'" >&2
    exit 1
    ;;
esac

# The .emscripten check guards against an interrupted bootstrap: emsdk
# activate writes it last, so its presence means install + activate finished.
prefix="$root/.emsdk/$host"
if [ -f "$prefix/upstream/emscripten/emcc" ] && [ -f "$prefix/.emscripten" ]; then
    echo "emscripten already installed at $prefix"
    exit 0
fi

if [ ! -f "$root/emsdk/emsdk.py" ]; then
    echo "emsdk submodule is missing or empty; run: git submodule update --init" >&2
    exit 1
fi

# emsdk installs into whatever directory its scripts run from, so copy the
# installer files out of the submodule and run them from the per-host prefix.
# build.zig (resolveEmscriptenRoot) mirrors this.
mkdir -p "$prefix"
find "$root/emsdk" -maxdepth 1 -type f -exec cp {} "$prefix/" \;
sh "$prefix/emsdk" install latest
sh "$prefix/emsdk" activate latest
