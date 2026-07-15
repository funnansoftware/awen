FROM ubuntu:25.10

ENV DEBIAN_FRONTEND=noninteractive

# Base utilities and build tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    make \
    cmake \
    ninja-build \
    pkg-config \
    python3 \
    zip \
    unzip \
    xz-utils \
    tar \
    && rm -rf /var/lib/apt/lists/*

# GCC 15.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-15 \
    g++-15 \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-15 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-15 100

# Add the official LLVM apt repository so clang-22 packages are available.
RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
    -o /usr/share/keyrings/llvm-apt-key.asc \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/llvm-apt-key.asc] http://apt.llvm.org/${UBUNTU_CODENAME}/ llvm-toolchain-${UBUNTU_CODENAME}-22 main" \
    > /etc/apt/sources.list.d/llvm-22.list

# Clang 22.
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang-22 \
    libclang-rt-22-dev \
    llvm-22 \
    clang-format-22 \
    clang-tidy-22 \
    clangd-22 \
    lld-22 \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-22 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-22 100 \
    && update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-22 100 \
    && update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-22 100 \
    && update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-22 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-22 100 \
    && update-alternatives --install /usr/bin/run-clang-tidy run-clang-tidy /usr/bin/run-clang-tidy-22 100 \
    && update-alternatives --install /usr/bin/clang-tidy-diff clang-tidy-diff /usr/bin/clang-tidy-diff-22.py 100 \
    && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-22 100 \
    && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-22 100

# Emulator runtime dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpulse0 \
    libgl1 \
    libnss3 \
    libxcomposite1 \
    libxcursor1 \
    libxi6 \
    libxtst6 \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    openjdk-17-jdk \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Android SDK command line tools.
RUN mkdir -p /opt/android/sdk \
    && curl -fsSLo /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip \
    && unzip -qq /tmp/commandlinetools.zip -d /opt/android/sdk \
    && rm -f /tmp/commandlinetools.zip

ENV ANDROID_HOME=/opt/android/sdk

RUN mkdir -p /opt/android/sdk/cmdline-tools/latest \
    && mv /opt/android/sdk/cmdline-tools/bin /opt/android/sdk/cmdline-tools/latest/ \
    && mv /opt/android/sdk/cmdline-tools/lib /opt/android/sdk/cmdline-tools/latest/ \
    && mv /opt/android/sdk/cmdline-tools/NOTICE.txt /opt/android/sdk/cmdline-tools/latest/ \
    && mv /opt/android/sdk/cmdline-tools/source.properties /opt/android/sdk/cmdline-tools/latest/ \
    && yes | /opt/android/sdk/cmdline-tools/latest/bin/sdkmanager --licenses \
    && /opt/android/sdk/cmdline-tools/latest/bin/sdkmanager \
    "platforms;android-36" \
    "build-tools;36.0.0" \
    "platform-tools" \
    "emulator" \
    "system-images;android-36.1;google_apis;x86_64"

# Create a default AVD for emulator usage inside the container.
RUN $ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
    -n pixel_avd \
    -k "system-images;android-36.1;google_apis;x86_64" \
    --device "pixel_6" \
    --force

# Android NDK r29.
ARG NDK_VERSION=r29
RUN mkdir -p /opt/android/ndk/android-ndk-${NDK_VERSION} \
    && curl -fsSLo /tmp/ndk.zip https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip \
    && unzip -q /tmp/ndk.zip -d /opt/android/ndk \
    && rm /tmp/ndk.zip

# Gradle (latest from https://gradle.org/releases/).
ARG GRADLE_VERSION=9.4.1
RUN curl -fsSLo /tmp/gradle.zip "https://services.gradle.org/distributions/gradle-${GRADLE_VERSION}-bin.zip" \
    && unzip -q /tmp/gradle.zip -d /opt \
    && ln -sf /opt/gradle-${GRADLE_VERSION}/bin/gradle /usr/local/bin/gradle \
    && rm /tmp/gradle.zip

ENV ANDROID_NDK_HOME=/opt/android/ndk/android-ndk-${NDK_VERSION}

ENV PATH=${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools:${ANDROID_NDK_HOME}:${PATH}

# Zig (kept in sync with the .zigversion file at the repo root).
ARG ZIG_VERSION=0.17.0-dev.1275+59a628c6d
RUN curl -fsSLo /tmp/zig.tar.xz "https://ziglang.org/builds/zig-x86_64-linux-${ZIG_VERSION}.tar.xz" \
    && mkdir -p /opt/zig \
    && tar -xJf /tmp/zig.tar.xz -C /opt/zig --strip-components=1 \
    && ln -sf /opt/zig/zig /usr/local/bin/zig \
    && rm /tmp/zig.tar.xz

# Raylib
RUN apt-get update && apt-get install -y \
    libxinerama-dev libxcursor-dev \
    xorg-dev libglu1-mesa-dev pkg-config

# Debug keystore so Android debug builds work without extra setup.
RUN mkdir -p /root/.android \
    && keytool -genkeypair \
    -v \
    -keystore /root/.android/debug.keystore \
    -storepass android \
    -alias androiddebugkey \
    -keypass android \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Android Debug, O=Android, C=US"

# Qt build dependencies — vcpkg builds Qt from source on linux (xcb windowing,
# EGL, xkbcommon) and its meta-build needs the autotools family.
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    autoconf-archive \
    automake \
    libtool \
    '^libxcb.*-dev' \
    libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libegl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*
