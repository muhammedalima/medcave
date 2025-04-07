-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Keep Firebase-related classes
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Pigeon-generated classes (adjust based on your Pigeon files)
-keep class io.flutter.plugins.** { *; }
-keep class com.example.medcave.** { *; }

# Prevent obfuscation of Firebase and Pigeon methods
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.plugins.**
-dontwarn com.example.medcave.**

# Keep Multidex and application classes
-keep class androidx.multidex.** { *; }
-keep public class * extends android.app.Application

# Keep model classes if any
-keepclassmembers class ** {
    @com.google.gson.annotations.SerializedName <fields>;
}