# Default to linux/amd64 — Android NDK host binaries are published for Linux x86_64.
# Override at build time with: --build-arg DEVCONTAINER_PLATFORM=linux/arm64
ARG DEVCONTAINER_PLATFORM=linux/amd64
FROM --platform=${DEVCONTAINER_PLATFORM} ubuntu:26.04

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
    openjdk-17-jdk \
    usbutils \
    && rm -rf /var/lib/apt/lists/*

# GCC 16.
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc-16 \
    g++-16 \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-16 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-16 100

# Add the official LLVM apt repository so clang-22 packages are available.
RUN curl -fsSL https://apt.llvm.org/llvm-snapshot.gpg.key \
    -o /usr/share/keyrings/llvm-apt-key.asc \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/llvm-apt-key.asc] http://apt.llvm.org/questing/ llvm-toolchain-questing-22 main" \
    > /etc/apt/sources.list.d/llvm-22.list

# Clang 22.
RUN apt-get update && apt-get install -y --no-install-recommends \
    clang-22 \
    clang-format-22 \
    clang-tidy-22 \
    clangd-22 \
    lld-22 \
    llvm-22 \
    && rm -rf /var/lib/apt/lists/* \
    && update-alternatives --install /usr/bin/clang clang /usr/bin/clang-22 100 \
    && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-22 100 \
    && update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-22 100 \
    && update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-22 100 \
    && update-alternatives --install /usr/bin/clangd clangd /usr/bin/clangd-22 100 \
    && update-alternatives --install /usr/bin/lld lld /usr/bin/lld-22 100 \
    && update-alternatives --install /usr/bin/llvm-cov llvm-cov /usr/bin/llvm-cov-22 100 \
    && update-alternatives --install /usr/bin/llvm-profdata llvm-profdata /usr/bin/llvm-profdata-22 100 \
    && update-alternatives --install /usr/bin/run-clang-tidy run-clang-tidy /usr/bin/run-clang-tidy-22 100 \
    && update-alternatives --install /usr/bin/clang-tidy-diff clang-tidy-diff /usr/bin/clang-tidy-diff-22.py 100

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

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Android SDK command line tools.
RUN mkdir -p /opt/android/sdk \
    && curl -fsSLo /tmp/commandlinetools.zip https://dl.google.com/android/repository/commandlinetools-linux-14742923_latest.zip \
    && unzip -qq /tmp/commandlinetools.zip -d /opt/android/sdk \
    && rm -f /tmp/commandlinetools.zip

ENV ANDROID_HOME=/opt/android/sdk
ENV ANDROID_SDK_HOME=/opt/android/sdk

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
    -n awen_avd \
    -k "system-images;android-36.1;google_apis;x86_64" \
    --device "pixel_6" \
    --force

# Android NDK r29.
ARG NDK_VERSION=r29
RUN mkdir -p /opt/android/ndk/android-ndk-${NDK_VERSION} \
    && curl -fsSLo /tmp/ndk.zip https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip \
    && unzip -q /tmp/ndk.zip -d /opt/android/ndk \
    && rm /tmp/ndk.zip

ENV ANDROID_NDK_HOME=/opt/android/ndk/android-ndk-${NDK_VERSION}

# Emscripten SDK for wasm toolchains.
ARG EMSDK_VERSION=latest
RUN git clone https://github.com/emscripten-core/emsdk.git /opt/emsdk \
    && /opt/emsdk/emsdk install ${EMSDK_VERSION} \
    && /opt/emsdk/emsdk activate ${EMSDK_VERSION} \
    && nodeBin="$(find /opt/emsdk/node -type f -path '*/bin/node' | head -n 1)" \
    && test -n "${nodeBin}" \
    && ln -sf "${nodeBin}" /usr/local/bin/node

ENV EMSDK=/opt/emsdk
ENV EMSCRIPTEN_ROOT=/opt/emsdk/upstream/emscripten
ENV PATH=${EMSDK}:${EMSCRIPTEN_ROOT}:${ANDROID_HOME}/emulator:${ANDROID_HOME}/platform-tools:${ANDROID_NDK_HOME}:${PATH}

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

# Qt Dependencies.
RUN apt-get update && apt-get install -y --no-install-recommends \
    autoconf \
    autoconf-archive \
    automake \
    libtool \
    '^libxcb.*-dev' \
    libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev \
    libxkbcommon-x11-dev libegl1-mesa-dev \
    && rm -rf /var/lib/apt/lists/*