plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.project"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.nady.dev1"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            storeFile = file("simi.jks")
            storePassword = "simi@2025"
            keyAlias = "key0"
            keyPassword = "simi@2025"
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    buildTypes {
        getByName("debug") {
            signingConfig = signingConfigs.getByName("release")
            val splitPerAbi = providers.gradleProperty("split-per-abi").orNull.toBoolean()
            if (!splitPerAbi) {
                val targetAbis = providers.gradleProperty("target-platform").orNull
                    ?.split(",")
                    ?.map { platform ->
                        when (platform.trim()) {
                            "android-arm" -> "armeabi-v7a"
                            "android-arm64" -> "arm64-v8a"
                            "android-x64" -> "x86_64"
                            else -> error("Unsupported Flutter target platform: $platform")
                        }
                    }
                if (!targetAbis.isNullOrEmpty()) {
                    ndk {
                        // Also filter third-party native libraries for the debug device.
                        abiFilters.clear()
                        abiFilters.addAll(targetAbis)
                    }
                }
            }
        }
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
                debugSymbolLevel = "FULL"
            }
            isCrunchPngs = false
            isDebuggable = false
            isZipAlignEnabled = true
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}
