import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val admobProperties = Properties()
val admobPropertiesFile = rootProject.file("admob.properties")
val hasAdmobProperties = admobPropertiesFile.exists()

if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

if (hasAdmobProperties) {
    admobProperties.load(FileInputStream(admobPropertiesFile))
}

val admobAndroidAppId =
    (admobProperties.getProperty("ADMOB_ANDROID_APP_ID")
        ?: "ca-app-pub-3940256099942544~3347511713").trim()

val isReleaseTask = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}

if (isReleaseTask && !hasReleaseKeystore) {
    throw GradleException(
        "Release signing is not configured. Add android/key.properties and a keystore file.",
    )
}

android {
    namespace = "com.picme.app.picme"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.picme.app.picme"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // Produce *.so.sym sidecars alongside stripped native libs. Required
            // by Flutter's post-build verification of release app bundles.
            debugSymbolLevel = "SYMBOL_TABLE"
        }

        manifestPlaceholders["admobAppId"] = admobAndroidAppId
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }

    packaging {
        jniLibs {
            // Extract native libs to filesystem on install. ReLinker (used by
            // FlutterJNI on some devices and by `datastore_shared_counter`)
            // needs filesystem-resident .so files; AGP's default of memory-mapped
            // libs causes "Could not find 'libflutter.so'" crashes on app launch.
            useLegacyPackaging = true
        }
    }
}

flutter {
    source = "../.."
}
