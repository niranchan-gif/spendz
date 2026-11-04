# ProGuard / R8 rules for Spendz 2.0 Release

# Flutter Secure Storage & AndroidX Keystore
-dontwarn androidx.security.crypto.**
-keep class androidx.security.crypto.** { *; }

# Biometrics
-dontwarn androidx.biometric.**
-keep class androidx.biometric.** { *; }

