# ProGuard / R8 rules for Spendz 2.0 Release

# Flutter Secure Storage & AndroidX Keystore
-dontwarn androidx.security.crypto.**
-keep class androidx.security.crypto.** { *; }

# Biometrics
-dontwarn androidx.biometric.**
-keep class androidx.biometric.** { *; }

# open_filex: preserve FileProvider and plugin class so R8 doesn't strip them in release
-keep class com.crazecoder.openfile.** { *; }
-keep class androidx.core.content.FileProvider { *; }

# share_plus: preserve ShareFileProvider so sharing works in release
-keep class dev.fluttercommunity.plus.share.** { *; }

# Syncfusion PDF
-dontwarn com.syncfusion.**
-keep class com.syncfusion.** { *; }

