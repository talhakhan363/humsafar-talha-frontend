# SEC-21 fix (Sarim's 22 Nov security review) — R8/ProGuard rules for the
# release build's new isMinifyEnabled/isShrinkResources (see
# build.gradle.kts). Flutter's own engine/framework classes are already
# covered by the Flutter Gradle plugin's own default rules; everything
# below is for this app's specific native/reflection-sensitive
# dependencies, which R8 would otherwise be free to rename and silently
# break (nothing throws — a renamed JNI target or receiver class just
# stops being found at runtime).
#
# IMPORTANT — this has NOT been verified against a real device: these
# rules are deliberately broad/defensive (keep more than strictly
# necessary) rather than guessed narrow, because the failure mode of
# "kept one class too many" is a slightly bigger release APK, while the
# failure mode of "kept one class too few" is calls or push notifications
# silently breaking in a build nobody is otherwise testing feature-by-
# feature. Still: run one real `flutter build apk --release`, install it,
# and actually place a test call + trigger a push notification before
# this build type is trusted for anything (the pitch included) — that one
# check is Talha's own normal "build and release" job per the team's
# working agreement, not a Sarim/Abdullah dependency.

# ZegoCloud (zego_uikit_prebuilt_call / zego_express_engine / the
# signaling plugin underneath) talk to their native SDK over JNI, which
# binds by exact class/method name from Kotlin/Java into native code —
# R8 renaming those names breaks the native side silently. This is
# ZegoCloud's own standard integration guidance for their Android SDKs,
# not something guessed from this app's behaviour.
-keep class im.zego.** { *; }
-dontwarn im.zego.**
-keep class com.zego.** { *; }
-dontwarn com.zego.**

# Firebase Cloud Messaging (Task 3.14): push payloads are read by
# field/key name in push_service.dart via platform channels, and FCM's
# own background-message handling touches these classes by name.
-keep class com.google.firebase.messaging.** { *; }
-dontwarn com.google.firebase.messaging.**

# flutter_local_notifications: its Android receivers/services are wired
# up by class name from the manifest, which R8 doesn't trace the way it
# traces normal code references.
-keep class com.dexterous.** { *; }
-dontwarn com.dexterous.**

# flutter_secure_storage (EncryptedSharedPreferences-backed, used for the
# refresh token — see api_config.dart/current_user_provider.dart) touches
# AndroidX Security classes reflectively on some API levels.
-keep class androidx.security.crypto.** { *; }

# General safety net: keep annotations (several plugins check for them at
# runtime), native method signatures (JNI binds by name), and the
# values()/valueOf() pair R8 can otherwise strip from enums some plugins
# serialize by name.
-keepattributes *Annotation*
-keepclassmembers class * {
    native <methods>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
