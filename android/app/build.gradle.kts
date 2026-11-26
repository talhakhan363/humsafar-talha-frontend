import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // Task 3.14 — Firebase. Must come after the Android/Kotlin/Flutter
    // plugins above; this is what actually reads android/app/google-services.json
    // and wires the Firebase config into the build.
    id("com.google.gms.google-services")
}

// Bug fix (SEC-19, Sarim's 22 Nov security review): release-build signing
// config, loaded from android/key.properties — already gitignored (see
// that .gitignore entry's own comment), so this file never has real
// values committed, and key.properties' own comment has the one-time
// `keytool` setup. Every read below is guarded by `.exists()` so a
// machine that hasn't done that setup yet still builds fine — it just
// silently falls back to the debug keystore for `--release` too, exactly
// like before this fix, instead of failing the build.
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
val keystoreProperties = Properties()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.humsafar_talha_frontend"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Task 3.14 — firebase_messaging / flutter_local_notifications pull in
        // java.time-style APIs that need core library desugaring on minSdk < 26.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Bug fix (SEC-19, Sarim's 22 Nov security review): flipped off the
        // Android Studio default "com.example.*" id, now that the release
        // keystore and the matching `com.humsafar.app` Firebase app both
        // exist (see android/key.properties' own comment and
        // google-services.json's second `client` entry). Deliberately left
        // `namespace` above untouched — it only has to match MainActivity.kt's
        // actual Kotlin package folder, not this id, and Android Gradle
        // Plugin has supported namespace != applicationId since AGP 7.
        applicationId = "com.humsafar.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 2026-10-22 — bumped from 23: the audio_session plugin (pulled in
        // by just_audio for voice-message playback, Task 4.8) requires
        // minSdk 24 and failed the manifest merge at 23. 24 = Android 7.0
        // (2016); negligible real-device impact.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    buildTypes {
        release {
            // Bug fix (SEC-19/SEC-21, Sarim's 22 Nov security review,
            // both Low/Medium): a `--release` build used to sign with the
            // debug keystore (same key as every Flutter dev machine's
            // default — anyone could re-sign a modified APK and it would
            // still "legitimately" look like an update) and shipped
            // completely unobfuscated (SEC-21: "the shared APK is a debug
            // build and its full source can be read" — true of a release
            // build too, with nothing below set). Both fine for Sarim's
            // everyday debug-apk-* QA installs (untouched — this block is
            // release-only), not fine for anything meant to leave the
            // team's hands (e.g. the Sindh Unlocked pitch). Falls back to
            // the debug keystore automatically until `android/key.properties`
            // exists (see its own comment for the one-time setup) so this
            // doesn't break a `--release` build run before that's done.
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    // Task 3.14 — required alongside isCoreLibraryDesugaringEnabled above.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.3")
}

flutter {
    source = "../.."
}
