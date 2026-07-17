# Overlay shadowing vcpkg's built-in arm64-android triplet: the six settings
# below are copied verbatim — CRT dynamic selects ANDROID_STL c++_shared, which
# qtbase hard-requires (QtPlatformAndroid.cmake), and system version 28 becomes
# ANDROID_PLATFORM android-28, Qt 6.11's own default and androiddeployqt's
# minSdk floor — plus the repo conventions: Qt ports build dynamically
# (mandatory on android — the qtbase port enforces ONLY_DYNAMIC_LIBRARY;
# androiddeployqt bundles the libQt6*.so into the APK alongside
# libc++_shared.so) and release-only dependencies (clang/ELF ABI, no
# debug/release split, so the android debug preset links these release
# libraries too, exactly like x64-linux and wasm32-emscripten).
#
# The qt ports need more than the NDK at build time: ANDROID_HOME (the SDK's
# android.jar for the Qt6 java bindings — the qtbase port fatals without it)
# and JAVA_HOME (find_package(Java) under vcpkg's scrubbed PATH). Neither is
# on vcpkg-tool's clean-environment keep-list, so pass them through; listing
# ANDROID_NDK_HOME too is redundant (it is on the keep-list) but documents the
# dependency. _UNTRACKED keeps these machine-specific paths out of the ABI
# hash — an NDK bump still rotates the hash via the detected compiler version.
set(VCPKG_ENV_PASSTHROUGH_UNTRACKED ANDROID_NDK_HOME ANDROID_HOME JAVA_HOME)

set(VCPKG_TARGET_ARCHITECTURE arm64)
set(VCPKG_CRT_LINKAGE dynamic)
set(VCPKG_LIBRARY_LINKAGE static)
if(PORT MATCHES "^qt")
    set(VCPKG_LIBRARY_LINKAGE dynamic)
endif()

set(VCPKG_CMAKE_SYSTEM_NAME Android)
set(VCPKG_CMAKE_SYSTEM_VERSION 28)
set(VCPKG_MAKE_BUILD_TRIPLET "--host=aarch64-linux-android")
set(VCPKG_CMAKE_CONFIGURE_OPTIONS -DANDROID_ABI=arm64-v8a)

set(VCPKG_BUILD_TYPE release)
