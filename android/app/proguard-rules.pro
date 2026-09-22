# Universal App Lock — R8/ProGuard rules
#
# androidx.security-crypto pulls in Google Tink, which references compile-time
# annotations (errorprone / javax.annotation) that are not present at runtime.
# These are safe to ignore for R8; without this, minifyReleaseWithR8 fails with
# "Missing classes detected while running R8".

-dontwarn com.google.errorprone.annotations.**
-dontwarn javax.annotation.**
-dontwarn javax.annotation.concurrent.**

# Keep Tink crypto classes used by EncryptedSharedPreferences at runtime.
-keep class com.google.crypto.tink.** { *; }
