# Add rules for missing classes from your error output
-dontwarn com.itgsa.opensdk.mediaunit.KaraokeMediaHelper
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.w3c.dom.bootstrap.DOMImplementationRegistry

# Flutter-specific rules
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }  # For Google Services (Firebase)
-keep class com.fasterxml.jackson.** { *; }  # For Jackson library (if used)

# Zego SDK rules (assuming this is related to com.itgsa.opensdk)
-keep class com.itgsa.opensdk.** { *; }
-dontwarn com.itgsa.opensdk.**

# General rules for Android and Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class androidx.** { *; }
-dontwarn androidx.**

# Prevent R8 from removing unused classes that might be referenced reflectively
-keepattributes Signature
-keepattributes Exceptions
-keepattributes *Annotation*

# Keep Google Play Core split install classes
-keep class com.google.android.play.** { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn com.google.android.play.core.**

-keep class **.zego.** { *; }