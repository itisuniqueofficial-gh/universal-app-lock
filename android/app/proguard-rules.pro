# Universal App Lock — R8/ProGuard rules
#
# androidx.security-crypto pulls in Google Tink, which references compile-time
# annotations (errorprone / javax.annotation) that are not present at runtime.
# These are safe to ignore for R8; without this, minifyReleaseWithR8 fails with
# "Missing classes detected while running R8".

-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**
# Tink's optional KeysDownloader references the Google HTTP client and Joda-Time,
# which we do not use (we only use local EncryptedSharedPreferences).
-dontwarn com.google.api.client.**
-dontwarn com.google.api.**
-dontwarn org.joda.time.**

# Keep Tink crypto classes used by EncryptedSharedPreferences at runtime.
-keep class com.google.crypto.tink.** { *; }
