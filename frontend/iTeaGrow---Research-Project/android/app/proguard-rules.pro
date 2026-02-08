# =============================================================================
# ProGuard Rules for iTeaGrow Production Release
# =============================================================================
# These rules optimize and obfuscate the app while preserving functionality

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve annotations
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exception

# Keep native methods
-keepclassmembers class * {
    native <methods>;
}

# Keep Parcelable classes
-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

# Keep Serializable classes
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# Keep enum classes
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# =============================================================================
# FLUTTER-SPECIFIC RULES
# =============================================================================

# Keep Dart classes
-keep class androidx.lifecycle.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# =============================================================================
# THIRD-PARTY LIBRARIES
# =============================================================================

# Riverpod (State Management)
-keep class com.riverpod.** { *; }

# HTTP/Networking
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# MQTT
-keep class org.eclipse.paho.** { *; }
-dontwarn org.eclipse.paho.**

# SQLite
-keep class androidx.sqlite.** { *; }

# Image Processing
-keep class com.bumptech.glide.** { *; }
-dontwarn com.bumptech.glide.**

# Camera
-keep class androidx.camera.** { *; }

# Location/GPS
-keep class com.google.android.gms.location.** { *; }

# Bluetooth
-keep class com.juul.kable.** { *; }
-dontwarn com.juul.kable.**

# =============================================================================
# OPTIMIZATION
# =============================================================================

# Optimize and obfuscate
-optimizationpasses 5
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-dontpreverify
-verbose

# Remove logging in production
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# =============================================================================
# DEBUGGING (Remove in final production if needed)
# =============================================================================

# Keep source file names and line numbers for better crash reports
-keepattributes SourceFile,LineNumberTable

# Rename source file to "SourceFile"
-renamesourcefileattribute SourceFile
