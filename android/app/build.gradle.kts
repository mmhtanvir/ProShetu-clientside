plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

// MAPS_API_KEY lives in android/gradle.properties (Gradle loads that
// file's keys into project properties automatically — no manual
// Properties parsing needed, unlike local.properties which only holds
// Flutter/SDK paths and never had this key).
val mapsApiKey: String = (project.findProperty("MAPS_API_KEY") as String?) ?: ""

android {
    namespace = "com.proshetu.app"
    // permission_handler_android (added for BLE mesh) requires
    // compileSdk 37 — flutter.compileSdkVersion (36) isn't enough.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Required by flutter_local_notifications, which uses Java 8+
        // APIs (java.time etc.) internally.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.proshetu.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["MAPS_API_KEY"] = mapsApiKey
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    // Pulled in by isCoreLibraryDesugaringEnabled above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
