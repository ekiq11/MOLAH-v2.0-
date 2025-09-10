import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pizab_molah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8  // 🔥 WAJIB 1_8
        targetCompatibility = JavaVersion.VERSION_1_8  // 🔥 WAJIB 1_8
        isCoreLibraryDesugaringEnabled = true          // ✅ AKTIFKAN INI
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }
    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.pizab_molah"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName 
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        getByName("debug") {
            // debug tetap default
        }
    }
}
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")

    // ✅ TAMBAHKAN BARIS INI
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Optional: jika kamu pakai multidex
    if (flutter.minSdkVersion < 21) {
        implementation("androidx.multidex:multidex:2.0.1")
    }
}
flutter {
    source = "../.."
}
