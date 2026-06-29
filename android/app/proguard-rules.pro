##################################################
# RetroVerse — ProGuard / R8 Rules
# Applies to all release builds
##################################################

#--------------------------------------------------
# 1. Flutter Engine & Embedding
#--------------------------------------------------
-keep class io.flutter.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.app.** { *; }
-keepattributes *Annotation*

#--------------------------------------------------
# 2. Flutter GeneratedPluginRegistrant
#--------------------------------------------------
-keep class com.arbaz.retrometro.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.editing.** { *; }

#--------------------------------------------------
# 3. Kotlin Metadata (required for reflection)
#--------------------------------------------------
-keepattributes RuntimeVisibleAnnotations
-keepattributes AnnotationDefault
-keep class kotlin.Metadata { *; }
-keep class kotlin.** { *; }
-keepclassmembers class kotlin.Metadata {
    public <methods>;
}
-dontwarn kotlin.**
-dontnote kotlin.**

#--------------------------------------------------
# 4. JNI / FFI / Native Libraries (libretro core)
#--------------------------------------------------
# Keep ALL JNI-called methods so native side can call back
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}
# Keep the FFI interop glue
-keep class com.sun.jna.** { *; }
-dontwarn com.sun.jna.**

#--------------------------------------------------
# 5. OkHttp / Okio (used by Dio under the hood)
#--------------------------------------------------
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-keep class okio.** { *; }

#--------------------------------------------------
# 6. Dio (HTTP client)
#--------------------------------------------------
-keep class dio.** { *; }
-keepnames class com.squareup.okhttp3.** { *; }
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**

#--------------------------------------------------
# 7. Shared Preferences
#--------------------------------------------------
-keep class androidx.datastore.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

#--------------------------------------------------
# 8. Path Provider / File Picker / URL Launcher
#--------------------------------------------------
-keep class androidx.core.content.FileProvider { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-dontwarn com.mr.flutter.plugin.filepicker.**
-keep class io.flutter.plugins.urllauncher.** { *; }
-dontwarn io.flutter.plugins.urllauncher.**
-keep class dev.fluttercommunity.plus.** { *; }
-dontwarn dev.fluttercommunity.plus.**

#--------------------------------------------------
# 9. Cached Network Image / Glide
#--------------------------------------------------
-keep public class * implements com.bumptech.glide.module.GlideModule
-keep class * extends com.bumptech.glide.module.AppGlideModule {
    <init>(...);
}
-keep public enum com.bumptech.glide.load.ImageHeaderParser$** {
    **[] $VALUES;
    public *;
}
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**
-dontwarn jp.co.cyberagent.android.gpuimage.**

#--------------------------------------------------
# 10. Google Fonts
#--------------------------------------------------
-keep class com.google.android.gms.fonts.** { *; }
-dontwarn com.google.android.gms.fonts.**

#--------------------------------------------------
# 11. AndroidX / Jetpack
#--------------------------------------------------
-keep class androidx.lifecycle.** { *; }
-dontwarn androidx.lifecycle.**
-keep class androidx.fragment.app.** { *; }
-keep class androidx.core.** { *; }
-dontwarn androidx.**

#--------------------------------------------------
# 12. Lottie Animations
#--------------------------------------------------
-keep class com.airbnb.lottie.** { *; }
-dontwarn com.airbnb.lottie.**

#--------------------------------------------------
# 13. Serialization helpers (JSON)
#--------------------------------------------------
-keepattributes Signature
-keepattributes Exceptions
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keepattributes SourceFile,LineNumberTable
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class org.json.** { *; }

#--------------------------------------------------
# 14. Security — rename source file attribute
#     (line numbers kept for crash reports, class names obfuscated)
#--------------------------------------------------
-renamesourcefileattribute SourceFile

#--------------------------------------------------
# 15. Reflection safety
#--------------------------------------------------
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

#--------------------------------------------------
# 16. Parcelable
#--------------------------------------------------
-keepclassmembers class * implements android.os.Parcelable {
    public static final android.os.Parcelable$Creator *;
}

#--------------------------------------------------
# 17. R class
#--------------------------------------------------
-keepclassmembers class **.R$* {
    public static <fields>;
}

#--------------------------------------------------
# 18. Suppress common harmless warnings
#--------------------------------------------------
-dontwarn sun.misc.**
-dontwarn java.lang.invoke.**
-dontwarn javax.annotation.**
-dontwarn org.xmlpull.**
-dontwarn android.support.**

#--------------------------------------------------
# 19. Google Play Core (Deferred/Split Components)
#     Flutter engine references these optionally —
#     not needed unless using deferred components.
#--------------------------------------------------
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-keep class com.google.android.play.core.splitcompat.SplitCompatApplication { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter deferred components manager — keep but ignore missing Play Core dep
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
