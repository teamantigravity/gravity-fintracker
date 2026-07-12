# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-dontwarn io.flutter.embedding.**

# Keep our own MainActivity (FlutterActivity subclass) — safe to keep, tiny surface
-keep class com.teamantigravity.gravityfintracker.** { *; }

# flutter_local_notifications uses reflection to resolve icons/receivers
-keep class com.dexterous.** { *; }

# sqflite
-keep class com.tekartik.sqflite.** { *; }

# flutter_secure_storage / AndroidX Security Crypto
-keep class androidx.security.crypto.** { *; }

# local_auth (biometrics)
-keep class io.flutter.plugins.localauth.** { *; }

# Gson / JSON reflection safety (if pulled in transitively)
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# General Android rules
-dontwarn org.jetbrains.annotations.**
-keepattributes SourceFile,LineNumberTable
