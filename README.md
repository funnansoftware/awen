# awen

![awen banner](banner.png)

[![windows](https://github.com/funnansoftware/awen/actions/workflows/windows.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/windows.yml)
[![macos](https://github.com/funnansoftware/awen/actions/workflows/macos.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/macos.yml)
[![linux](https://github.com/funnansoftware/awen/actions/workflows/linux.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/linux.yml)
[![coverage](https://github.com/funnansoftware/awen/actions/workflows/coverage.yml/badge.svg?branch=main)](https://github.com/funnansoftware/awen/actions/workflows/coverage.yml)

A C++23 application framework built around Qt Quick. The framework's QML
modules live under `src/`; the apps built on it live under `app/`:

- **awen** — the framework sample app.
- **[briarthorn](app/briarthorn)** — a flight/combat roguelike (its own
  [non-commercial license](app/briarthorn/LICENSE.md)).

Qt Quick is the sole rendering backend. vcpkg builds Qt from source on the first
configure; the Qt libraries link dynamically while everything else links
statically — the custom triplets in [cmake/triplets](cmake/triplets) draw that
line.

# Get Started

- [Prerequisites](#prerequisites)
- [Platforms](#platforms)
  - [windows](#windows)
  - [linux](#linux)
  - [mac](#macos)
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

The presets build Qt from source via vcpkg on the first configure — expect that
one-time step to take a while. It is binary-cached afterwards.

# Platforms

## Windows

Run from a Visual Studio 2022 developer shell:

```sh
cmake --preset windows                            # configure (release)
cmake --build --preset windows                    # build
cmake --build --preset windows --target install   # install
build/windows/installed/bin/briarthorn.exe        # run the game
build/windows/installed/bin/awen.exe              # run the framework sample
```

## Linux

```sh
cmake --preset linux                            # configure (release)
cmake --build --preset linux                    # build
cmake --build --preset linux --target install   # install
./build/linux/installed/bin/briarthorn          # run
```

## MacOS

```sh
cmake --preset macos                            # configure (release)
cmake --build --preset macos                    # build
cmake --build --preset macos --target install   # install
./build/macos/installed/bin/briarthorn          # run
```

# License

MIT — see [LICENSE](LICENSE). The briarthorn app is the exception: it is
licensed for non-commercial use only — see
[app/briarthorn/LICENSE.md](app/briarthorn/LICENSE.md).
