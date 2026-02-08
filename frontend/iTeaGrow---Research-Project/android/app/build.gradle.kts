import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.iteagrow.disease_detection"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

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
        targetSdk = 34  // Android 14 - latest stable

        // App version
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex for large apps
        multiDexEnabled = true

        // Production metadata
        setProperty("archivesBaseName", "iTeaGrow-v$versionName")
    }

    signingConfigs {
        // Debug signing (for development)
        getByName("debug") {
            storeFile = file("debug.keystore")
        }

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
            }
        }
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
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
}

flutter {
    source = "../.."
}
