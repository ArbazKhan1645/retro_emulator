plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.arbaz.retrometro"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.arbaz.retrometro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // ── Signing ───────────────────────────────────────────────
    signingConfigs {
        getByName("debug") {
            // debug keystore stays as-is
        }
        // Add a 'release' signing config here when you have a keystore:
        // create("release") {
        //     storeFile = file(System.getenv("KEYSTORE_PATH") ?: "release.keystore")
        //     storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
        //     keyAlias = System.getenv("KEY_ALIAS") ?: ""
        //     keyPassword = System.getenv("KEY_PASSWORD") ?: ""
        // }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
        release {
            // ── Minification & Obfuscation (R8 full mode) ─────
            isMinifyEnabled = true
            isShrinkResources = true

            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            // Use debug signing until you set up release keystore
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ── ABI Splits — only active when building with --split-per-abi ──────
    // Flutter automatically passes -Psplit-per-abi for that flag.
    // During `flutter run` (debug) this stays disabled so no conflict occurs.
    splits {
        abi {
            isEnable = project.hasProperty("split-per-abi")
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64")
            isUniversalApk = false   // set true only if you need a fat APK
        }
    }

    // ── Packaging options ─────────────────────────────────────
    packaging {
        resources {
            // Strip duplicate META-INF files that cause merge conflicts
            excludes += setOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/*.kotlin_module",
                "META-INF/AL2.0",
                "META-INF/LGPL2.1",
                "**/attach_hotspot_windows.dll",
                "**.proto",
            )
            // Merge duplicate service files rather than excluding
            merges += setOf("META-INF/services/**")
        }
        jniLibs {
            // Do NOT extract native libs to filesystem — Android loads directly
            // from compressed APK, saving extra disk space on the device
            useLegacyPackaging = false
        }
    }

    // ── Bundle optimizations (for AAB / Play Store) ───────────
    bundle {
        language {
            enableSplit = true   // separate APKs per language
        }
        density {
            enableSplit = true   // separate APKs per screen density
        }
        abi {
            enableSplit = true   // separate APKs per ABI
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
