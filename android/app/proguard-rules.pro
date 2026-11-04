# ProGuard / R8 rules for Spendz 2.0 Release

# Google ML Kit Text Recognition
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**
-dontwarn com.google.mlkit.vision.text.**
-keep class com.google.mlkit.vision.text.** { *; }

# Google ML Kit Document Scanner
-dontwarn com.google.android.gms.vision.**
-keep class com.google.android.gms.vision.** { *; }

# Flutter Secure Storage & AndroidX Keystore
-dontwarn androidx.security.crypto.**
-keep class androidx.security.crypto.** { *; }

# Biometrics
-dontwarn androidx.biometric.**
-keep class androidx.biometric.** { *; }

