import java.util.Properties

plugins {
    id("com.android.application")
}

// Detect host OS to select the correct vcpkg host triplet.
val vcpkgHostTriplet = if (System.getProperty("os.name").contains("Windows", ignoreCase = true)) {
    "x64-windows"
} else {
    "x64-linux"
}

// When the zig build drives packaging (zig build -Dtarget=<arch>-linux-android),
// it stages the prebuilt native library under <dir>/<abi>/ and passes
// -PzigJniLibs=<dir>; the CMake externalNativeBuild is skipped entirely and the
// staged library is packaged instead.
val zigJniLibs: String? = (project.findProperty("zigJniLibs") as String?)?.takeIf { it.isNotEmpty() }

// Read sdk.dir from local.properties (written by cmake/android/toolchain.cmake with
// forward slashes) so we can pass the NDK path to cmake with forward slashes.
// AGP's NdkHandler uses Java's File.absolutePath which produces backslashes on Windows;
// cmake 4.x strict string parsing then rejects \U, \a, etc. in the generated
// CMakeSystem.cmake.  Passing the same path in forward-slash form last on the command
// line overrides AGP's backslash value (cmake last-write-wins for cache entries).
val ndkVersion = "29.0.14206865"
val ndkDirForCmake: String = run {
    val propsFile = rootDir.resolve("local.properties")
    if (propsFile.exists()) {
        val props = Properties()
        props.load(propsFile.inputStream())
        val sdkDir = props.getProperty("sdk.dir", "")
        if (sdkDir.isNotEmpty()) "$sdkDir/ndk/$ndkVersion" else ""
    } else ""
}

android {
    namespace     = "com.funnansoftware.briarthorn"
    compileSdk    = 36
    // Must match Pkg.Revision in $ANDROID_NDK_HOME/source.properties
    ndkVersion    = "29.0.14206865"

    defaultConfig {
        applicationId = "com.funnansoftware.briarthorn"
        minSdk        = 26
        targetSdk     = 36
        versionCode   = 1
        versionName   = "1.0"

        if (zigJniLibs == null) ndk {
            // Only package the arm64-v8a ABI; add "x86_64" for emulator support.
            // (When zig stages the library, the jniLibs dir contains exactly the
            // target's ABI, so no filter is needed.)
            abiFilters += "arm64-v8a"
        }

        if (zigJniLibs == null) externalNativeBuild {
            cmake {
                // vcpkg is the primary toolchain; it chain-loads the NDK toolchain.
                // AGP still injects ANDROID_ABI / ANDROID_PLATFORM via its own
                // arguments, so those do not need to be repeated here.
                val cmakeArgs = mutableListOf(
                    // vcpkg is the primary toolchain; chain-load the NDK toolchain through it.
                    "-DCMAKE_TOOLCHAIN_FILE=${rootDir.parentFile.absolutePath.replace('\\', '/')}/vcpkg/scripts/buildsystems/vcpkg.cmake",
                    "-DVCPKG_CHAINLOAD_TOOLCHAIN_FILE=${ndkDirForCmake.ifEmpty { "\$ANDROID_NDK_HOME" }}/build/cmake/android.toolchain.cmake",
                    "-DVCPKG_TARGET_TRIPLET=arm64-android",
                    "-DVCPKG_HOST_TRIPLET=$vcpkgHostTriplet",
                    // Keep all vcpkg dependencies as static libs; only our app
                    // target is explicitly built as SHARED (see src/CMakeLists.txt)
                    "-DBUILD_SHARED_LIBS=OFF"
                )
                // On Windows, AGP's NdkHandler produces backslash paths which cmake 4.x
                // writes verbatim into CMakeSystem.cmake.  cmake then fails to re-read
                // the file because \U, \a, etc. are invalid cmake escape sequences.
                // Override with forward-slash paths from local.properties (last -D wins).
                if (ndkDirForCmake.isNotEmpty()) {
                    cmakeArgs += "-DANDROID_NDK=$ndkDirForCmake"
                    cmakeArgs += "-DCMAKE_ANDROID_NDK=$ndkDirForCmake"
                }
                arguments(*cmakeArgs.toTypedArray())
                // Only build the app shared library; skip tests and other targets
                targets("briarthorn")
            }
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // Use the auto-generated debug keystore for now.
            // Replace with a real release keystore before publishing to the Play Store.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    val stagedJniLibs = zigJniLibs
    if (stagedJniLibs == null) externalNativeBuild {
        cmake {
            // Path is relative to this build.gradle.kts file (android/app/)
            path    = file("../../CMakeLists.txt")
            version = "3.28.3+"
        }
    } else sourceSets {
        getByName("main") {
            jniLibs.srcDir(stagedJniLibs)
        }
    }
}
