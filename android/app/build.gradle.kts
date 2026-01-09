import java.util.Properties
import java.io.FileInputStream

// ===============================
// Load keystore properties
// ===============================
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// ===============================
// Plugins
// ===============================
plugins {
    id("com.android.application")
    id("kotlin-android")
    // Flutter Gradle Plugin HARUS terakhir
    id("dev.flutter.flutter-gradle-plugin")
}

// ===============================
// Android Configuration
// ===============================
android {
    namespace = "com.pizab_molah"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ===========================
    // Java & Kotlin Options
    // ===========================
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    // ===========================
    // Signing Config
    // ===========================
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    // ===========================
    // Default Config
    // ===========================
    defaultConfig {
        applicationId = "com.pizab_molah"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // 🔥 WAJIB untuk minSdk < 21
        multiDexEnabled = true
    }

    // ===========================
    // Build Types
    // ===========================
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
            // default
        }
    }
}

// ===============================
// Dependencies (KTS SYNTAX)
// ===============================
dependencies {
    implementation("androidx.core:core-ktx:1.13.1")

    implementation("com.google.android.play:app-update:2.1.0")
    implementation("com.google.android.play:review:2.0.1")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.multidex:multidex:2.0.1")
}

// ===============================
// Flutter Source
// ===============================
flutter {
    source = "../.."
}
