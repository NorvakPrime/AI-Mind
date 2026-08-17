# Chaquopy rules
-keep class com.chaquo.python.** { *; }
-keep interface com.chaquo.python.** { *; }

# Prevent stripping of native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# AI Mind classes that might be called from Python or via Reflection
-keep class com.norvak.ai_mind.** { *; }

# Flutter and generic Android
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.embedding.engine.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.external.org.apache.commons.logging.** { *; }

-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }