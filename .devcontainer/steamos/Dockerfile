# Steam Deck build container — Steam Linux Runtime 3.0 "sniper".
#
# This image exists for BINARY COMPATIBILITY with the Steam Deck, not for the
# newest toolchain. briarthorn's linux build is *native*: the zig toolchain links
# against the build machine's glibc (see cmake/toolchain/zig-linux.cmake and
# build.zig), so a binary's minimum glibc equals the glibc of the container it was
# built in. The main devcontainer is Ubuntu 25.10 with a bleeding-edge glibc;
# anything built there fails on the Deck with "version `GLIBC_x.xx' not found".
#
# Sniper is Steam Linux Runtime 3.0 — the container Steam guarantees at game launch
# on the Deck and every other Steam platform. It is Debian 11 based (glibc 2.31),
# below the Deck's ~2.37, and glibc is forward-compatible, so a binary built here
# runs both directly in SteamOS Desktop Mode and inside the Steam runtime
# container. Pin a dated 3.0.* tag instead of :latest for stricter reproducibility.
#
# Image ref: https://gitlab.steamos.cloud/steamrt/steamrt/-/blob/steamrt/sniper/README.md
FROM registry.gitlab.steamos.cloud/steamrt/sniper/sdk:latest

ENV DEBIAN_FRONTEND=noninteractive

# Build tooling. Zig is the whole toolchain (it bundles clang + libc++), so we do
# NOT install gcc/clang — Debian 11's gcc-10/clang-11 cannot compile C++23 anyway.
# make + ninja are here so the in-container linux-zig CMake presets work (they use
# the default Make generator); binutils provides objdump for the glibc-floor check.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    make \
    ninja-build \
    binutils \
    pkg-config \
    python3 \
    zip \
    unzip \
    xz-utils \
    tar \
    && rm -rf /var/lib/apt/lists/*

# X11 / GL development headers raylib's windowing layer (GLFW) is built against by
# vcpkg — the same set as the main Dockerfile and the README prerequisites. The
# sniper SDK already ships these; we install explicitly so the image is
# self-describing and resilient to SDK drift.
RUN apt-get update && apt-get install -y --no-install-recommends \
    xorg-dev \
    libxinerama-dev \
    libxcursor-dev \
    libglu1-mesa-dev \
    libgl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# On first use zig compiles libc++ from source for the native target, and for a
# native glibc target it uses the *system* headers: <errno.h> pulls in
# <linux/errno.h> -> <asm/errno.h>. On Debian multiarch the asm headers live
# under /usr/include/x86_64-linux-gnu/asm, but zig's native libc detection only
# adds /usr/include here (the Ubuntu devcontainer's zig finds the multiarch dir
# on its own; this older base does not). Install the kernel userspace headers and
# expose asm/ at the generic path so the include resolves — otherwise the very
# first `zig c++` fails with "'asm/errno.h' file not found".
RUN apt-get update && apt-get install -y --no-install-recommends linux-libc-dev \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sfn x86_64-linux-gnu/asm /usr/include/asm

# Modern CMake. The presets use schema "version": 7 and CMakeLists requires
# CMake >= 3.31; Debian 11 ships 3.18 and Kitware's apt repo is Ubuntu-only, so
# install the official upstream binary release directly.
ARG CMAKE_VERSION=3.31.12
RUN curl -fsSLo /tmp/cmake.tar.gz \
    "https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz" \
    && mkdir -p /opt \
    && tar -xzf /tmp/cmake.tar.gz -C /opt \
    && rm /tmp/cmake.tar.gz \
    && ln -sf "/opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/cmake" /usr/local/bin/cmake \
    && ln -sf "/opt/cmake-${CMAKE_VERSION}-linux-x86_64/bin/ctest" /usr/local/bin/ctest

# Zig (kept in sync with the .zigversion file at the repo root).
ARG ZIG_VERSION=0.17.0-dev.1275+59a628c6d
RUN curl -fsSLo /tmp/zig.tar.xz "https://ziglang.org/builds/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" \
    && mkdir -p /opt/zig \
    && tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 \
    && ln -sf /opt/zig/zig /usr/local/bin/zig \
    && rm /tmp/zig.tar.xz
