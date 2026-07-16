#!/bin/sh
# Bootstraps the emscripten toolchain into a per-host prefix (.emsdk/<host>).
#
# The emsdk submodule stays pristine: it only supplies the installer scripts.
# Installs are keyed by host OS because the toolchain binaries are
# platform-specific: one working tree may be shared across operating systems
# (WSL, devcontainers), and a single shared install would be clobbered on every
# switch.
#
# The version is pinned in .emscripten-version rather than tracking "latest",
# because Qt requires one specific emscripten release: Qt bakes the emscripten
# version it was built with into qconfig.h and _qt_test_emscripten_version()
# aborts when an app is built with a different one. vcpkg's qtbase port strips
# that check (see its portfile), so a mismatch would not be caught at configure
# time — it would surface later as a link or runtime failure. Keep this file in
# step with QT_EMCC_RECOMMENDED_VERSION in qtbase's
# cmake/QtPublicWasmToolchainHelpers.cmake when bumping Qt.
#
# On Windows, use scripts/bootstrap-emsdk.bat instead.
set -eu

root="$(cd "$(dirname "$0")/.." && pwd)"

# Matches CMake's ${hostSystemName} so the presets address the same directory.
host="$(uname -s)"
case "$host" in
Linux | Darwin) ;;
*)
    echo "unsupported host '$host'; on Windows run scripts/bootstrap-emsdk.bat" >&2
    exit 1
    ;;
esac

version="$(tr -d ' \t\r\n' <"$root/.emscripten-version")"
if [ -z "$version" ]; then
    echo "no version found in .emscripten-version" >&2
    exit 1
fi

# The .emscripten check guards against an interrupted bootstrap: emsdk
# activate writes it last, so its presence means install + activate finished.
# The stamp records which version that was, so a bump re-bootstraps instead of
# silently reusing the old toolchain.
prefix="$root/.emsdk/$host"
stamp="$prefix/.awen-emsdk-version"
if [ -f "$prefix/upstream/emscripten/emcc" ] && [ -f "$prefix/.emscripten" ] &&
    [ -f "$stamp" ] && [ "$(cat "$stamp")" = "$version" ]; then
    echo "emscripten $version already installed at $prefix"
    exit 0
fi

if [ ! -f "$root/emsdk/emsdk.py" ]; then
    echo "emsdk submodule is missing or empty; run: git submodule update --init" >&2
    exit 1
fi

# emsdk installs into whatever directory its scripts run from, so copy the
# installer files out of the submodule and run them from the per-host prefix.
mkdir -p "$prefix"
find "$root/emsdk" -maxdepth 1 -type f -exec cp {} "$prefix/" \;
sh "$prefix/emsdk" install "$version"
sh "$prefix/emsdk" activate "$version"
printf '%s' "$version" >"$stamp"
