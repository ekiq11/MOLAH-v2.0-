# Jangan potong url_launcher
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.common.** { *; }
# Play Core modern
-keep class com.google.android.play.** { *; }
-dontwarn com.google.android.play.**