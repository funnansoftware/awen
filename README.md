# awen

[![windows](https://github.com/funnansoftware/awen/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/windows.yml)
[![macos](https://github.com/funnansoftware/awen/actions/workflows/macos.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/macos.yml)
[![linux](https://github.com/funnansoftware/awen/actions/workflows/linux.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/linux.yml)
[![coverage](https://github.com/funnansoftware/awen/actions/workflows/coverage.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/coverage.yml)
[![steamos](https://github.com/funnansoftware/awen/actions/workflows/steamos.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/steamos.yml)
[![web](https://github.com/funnansoftware/awen/actions/workflows/web.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/web.yml)
[![android](https://github.com/funnansoftware/awen/actions/workflows/android.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/android.yml)

A C++23 application framework built around Qt Quick. The framework's QML
modules live under `src/`; the apps built on it live under `app/`:

- **awen** — the framework sample app.
- **[briarthorn](app/briarthorn)** — a flight/combat roguelike (its own
  [non-commercial license](app/briarthorn/LICENSE.md)).

[![briarthorn](app/briarthorn/assets/briarthorn.png)](app/briarthorn)

Qt Quick is the sole rendering backend. Qt itself comes prebuilt when a kit is
found (an official [Qt installer](https://www.qt.io/download-qt-installer-oss)
or [aqtinstall](https://github.com/miurahr/aqtinstall) install — `C:\Qt`,
`~/Qt`, or the `QT_ROOT_DIR` environment variable), and is otherwise built from
source by vcpkg on the first configure; `-DAWEN_QT=vcpkg|prebuilt` pins the
choice. Either way vcpkg provides the remaining dependencies: the Qt libraries
link dynamically while everything else links statically — the custom triplets
in [cmake/triplets](cmake/triplets) draw that line. Dependencies build in
release only (debug app builds link the release libraries), except on the
windows debug preset, where MSVC requires debug dependencies and the
`x64-windows` triplet keeps both configurations.

# Get Started

- [Prerequisites](#prerequisites)
- [Platforms](#platforms)
  - [windows](#windows)
  - [linux](#linux)
  - [mac](#macos)
  - [web](#web)
  - [android](#android)
- [License](#license)

# Prerequisites

awen vendors vcpkg as a submodule, so clone recursively:

```sh
git clone --recurse-submodules https://github.com/funnansoftware/awen.git
```

Every build needs [git](https://git-scm.com/),
[CMake](https://cmake.org/download/) &ge; 3.31,
[Ninja](https://github.com/ninja-build/ninja/releases), and a C++23 compiler:
Visual Studio 2022 (Windows), GCC (Linux), or Homebrew LLVM (`brew install
llvm@21`, macOS).

| OS      | Also needs                                                                              |
| ------- | --------------------------------------------------------------------------------------- |
| Linux   | Qt's build dependencies — the xcb/EGL/xkbcommon headers plus the autotools family. The [Dockerfile](.devcontainer/Dockerfile) lists the exact set, and the devcontainer installs them for you. |
| macOS   | Xcode Command Line Tools: `xcode-select --install`, and `brew install pkg-config`        |
| Windows | nothing extra — the Windows SDK from Visual Studio covers it                             |

Without a prebuilt Qt kit (&ge; 6.11, matching the target: `msvc2022_64`,
`gcc_64`, `macos`, `wasm_singlethread`, or `android_arm64_v8a`), the presets
build Qt from source via vcpkg on the first configure — expect that one-time
step to take a while. It is binary-cached afterwards.

# Platforms

## Windows

Run from a Visual Studio 2022 developer shell:

```sh
cmake --preset windows                            # configure (release)
cmake --build --preset windows                    # build
cmake --build --preset windows --target install   # install
build/windows/installed/briarthorn/bin/briarthorn.exe   # run the game
build/windows/installed/awen/bin/awen.exe               # run the framework sample
```

## Linux

```sh
cmake --preset linux                            # configure (release)
cmake --build --preset linux                    # build
cmake --build --preset linux --target install   # install
./build/linux/installed/briarthorn/bin/briarthorn   # run
```

## MacOS

```sh
cmake --preset macos                            # configure (release)
cmake --build --preset macos                    # build
cmake --build --preset macos --target install   # install
open ./build/macos/installed/briarthorn/briarthorn.app   # run
```

## Web

Cross-compiles from any desktop host. Bootstrap the pinned emscripten toolchain
once (`scripts/bootstrap-emsdk.sh`, or `scripts\bootstrap-emsdk.bat` on
Windows), then serve the output over http:

```sh
cmake --preset web                            # configure (release)
cmake --build --preset web                    # build
cmake --build --preset web --target install   # install
python3 -m http.server -d build/web/installed/web/briarthorn
# open http://localhost:8000/   (serves briarthorn's index.html)
```

## Android

Cross-compiles from any desktop host. Needs an Android SDK (`ANDROID_HOME` set)
with platform + build-tools installed, the NDK pinned in
[.android-ndk-version](.android-ndk-version) (`sdkmanager --install
"ndk;$(cat .android-ndk-version)"`), and a JDK (21 recommended) on `JAVA_HOME`.
The APK is assembled by Qt's androiddeployqt as part of the build:

```sh
cmake --preset android                            # configure (release)
cmake --build --preset android                    # build (also packages APKs)
cmake --build --preset android --target install   # install
# APKs: build/android/installed/android/{briarthorn,awen}.apk
```

# License

MIT — see [LICENSE](LICENSE). The briarthorn app is the exception: it is
licensed for non-commercial use only — see
[app/briarthorn/LICENSE.md](app/briarthorn/LICENSE.md).
