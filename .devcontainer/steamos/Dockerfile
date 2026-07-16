# Steam Deck build container — Steam Linux Runtime 3.0 "sniper".
#
# This image exists for BINARY COMPATIBILITY with the Steam Deck, not for the
# newest toolchain. The linux build is *native*: a binary's minimum glibc equals
# the glibc of the container it was built in, and vcpkg builds Qt from source in
# that same container, so the deployed Qt libraries inherit the same floor. The
# main devcontainer is Ubuntu 25.10 with a bleeding-edge glibc; anything built
# there fails on the Deck with "version `GLIBC_x.xx' not found".
#
# Sniper is Steam Linux Runtime 3.0 — the container Steam guarantees at game
# launch on the Deck and every other Steam platform. It is Debian 11 based
# (glibc 2.31), below the Deck's ~2.37, and glibc is forward-compatible, so a
# binary built here runs both directly in SteamOS Desktop Mode and inside the
# Steam runtime container. Pin a dated 3.0.* tag instead of :latest for stricter
# reproducibility.
#
# Image ref: https://gitlab.steamos.cloud/steamrt/steamrt/-/blob/steamrt/sniper/README.md
FROM registry.gitlab.steamos.cloud/steamrt/sniper/sdk:latest

ENV DEBIAN_FRONTEND=noninteractive

# Base utilities and build tooling — the same set as the main Dockerfile (minus
# cmake, handled below); binutils provides the objdump the CI glibc-floor check
# runs over the installed tree. The sniper SDK ships most of this already; we
# install explicitly so the image is self-describing and resilient to SDK drift.
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

# GCC 14, Valve's backport in the sniper SDK repos. Debian 11's own gcc-10 /
# clang-11 cannot compile C++23 (or Qt 6.11) — the backport is what makes a
# modern build possible while keeping the glibc 2.31 floor. Its libstdc++ is
# newer than the base system's, but that is the supported path: the Steam Linux
# Runtime uses the newest libstdc++ of host vs runtime at game launch, and
# SteamOS's own libstdc++ is newer still.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-14 \
    g++-14 \
    && rm -rf /var/lib/apt/lists/*

# CMake's compiler detection honors CC/CXX, and vcpkg's port builds go through
# that detection — this is what points the whole dependency tree (Qt included)
# at the gcc-14 backport instead of the SDK's default gcc-10, which plain
# `cc`/`c++` still resolve to. The steamos preset pins the same pair for the
# project itself.
ENV CC=gcc-14 \
    CXX=g++-14

# Qt build dependencies — vcpkg builds Qt from source on linux (xcb windowing,
# EGL, xkbcommon) and its meta-build needs the autotools family. Same set as
# the main Dockerfile.
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    autoconf-archive \
    automake \
    libtool \
    '^libxcb.*-dev' \
    libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libegl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*

# Modern Autoconf. vcpkg's gperf port (a fontconfig build tool) autoreconfs a
# configure.ac that requires Autoconf >= 2.70; Debian 11 ships 2.69 with no
# backport, so build the upstream release into /usr/local, which shadows the
# apt autoconf on PATH. automake/libtool stay the apt versions — vcpkg vendors
# its own automake (vcpkg-make port) and only autoconf is too old.
ARG AUTOCONF_VERSION=2.72
RUN curl -fsSLo /tmp/autoconf.tar.xz \
    "https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.xz" \
    && mkdir -p /tmp/autoconf \
    && tar -xJf /tmp/autoconf.tar.xz -C /tmp/autoconf --strip-components=1 \
    && cd /tmp/autoconf \
    && ./configure --prefix=/usr/local \
    && make \
    && make install \
    && cd / \
    && rm -rf /tmp/autoconf /tmp/autoconf.tar.xz

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
