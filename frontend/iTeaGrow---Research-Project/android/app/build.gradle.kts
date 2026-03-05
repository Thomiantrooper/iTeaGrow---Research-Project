import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Uncomment after placing google-services.json in android/app/
    id("com.google.gms.google-services")
}

android {
    namespace = "com.iteagrow.disease_detection"
    compileSdk = 35
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        // Production Application ID
        applicationId = "com.iteagrow.disease_detection"

        // Android versions
        minSdk = 26  // Android 8.0 (Oreo) - required by tflite_flutter
        targetSdk = 35  // Android 15

        // App version
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for large apps
        multiDexEnabled = true
        multiDexEnabled = true

        // Production metadata
        setProperty("archivesBaseName", "iTeaGrow-v$versionName")
    }

    signingConfigs {
        // Release signing (for production)
        create("release") {
            // Read from local.properties or environment variables
            val keystorePropertiesFile = rootProject.file("key.properties")
            if (keystorePropertiesFile.exists()) {
                val keystoreProperties = Properties()
                keystoreProperties.load(FileInputStream(keystorePropertiesFile))

                storeFile = file(keystoreProperties["storeFile"].toString())
                storePassword = keystoreProperties["storePassword"].toString()
                keyAlias = keystoreProperties["keyAlias"].toString()
                keyPassword = keystoreProperties["keyPassword"].toString()
            } else {
                // Fallback to debug keys if release keys not configured
                storeFile = file("debug.keystore")
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        getByName("debug") {
            isDebuggable = true
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }

        getByName("release") {
            // Production optimizations
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false

            // ProGuard rules
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            signingConfig = signingConfigs.getByName("release")

            // NDK optimization
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
            }
        }
    }

    // Lint options
    lint {
        checkReleaseBuilds = true
        abortOnError = false
    }

    // CRITICAL: Prevent compression of TFLite models
    // Required for Flex delegates and XNNPack
    aaptOptions {
        noCompress("tflite")
        noCompress("lite")
    }
}

flutter {
    source = "../.."
}

dependencies {
    // =========================================
    // PYTORCH MOBILE DEPENDENCIES
    // =========================================
    // Plugin 'pytorch_lite' manages its own dependencies (pytorch_android 2.1.0)
    // Removed manual entries to avoid JNI conflicts

    // =========================================
    // TENSORFLOW LITE DEPENDENCIES (CRITICAL)
    // =========================================

    // 1. CORE TFLite runtime (REQUIRED)
    implementation("org.tensorflow:tensorflow-lite:2.14.0")

    // 2. Flex ops support (REQUIRED for ShuffleNetV2)
    implementation("org.tensorflow:tensorflow-lite-select-tf-ops:2.14.0")

    // 3. Support library for easier preprocessing (OPTIONAL but recommended)
    implementation("org.tensorflow:tensorflow-lite-support:0.4.4")

    // 4. Multidex for large apps
    implementation("androidx.multidex:multidex:2.0.1")
}
