package com.itisuniqueofficial.ual.platform

import android.app.KeyguardManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build

/**
 * AuthenticationManager coordinates local authentication capabilities.
 *
 * PIN secret handling is delegated to [SecureCredentialStore] (Keystore-backed,
 * PBKDF2). Biometric support is limited to a read-only availability probe in
 * this phase; the actual BiometricPrompt flow is a later feature branch. No
 * secrets are logged.
 */
class AuthenticationManager(context: Context) {

    private val appContext = context.applicationContext
    private val store = SecureCredentialStore(appContext)

    // --- PIN ------------------------------------------------------------------

    fun hasPin(): Boolean = store.hasPin()

    fun setPin(pin: String): Boolean = store.setPin(pin.toCharArray())

    fun verifyPin(pin: String): Boolean = store.verifyPin(pin.toCharArray())

    fun clearPin(): Boolean = store.clearPin()

    // --- Biometric availability (informational only) --------------------------

    /** Returns "available", "not_enrolled", or "unavailable". */
    fun biometricAvailability(): String {
        return try {
            val pm = appContext.packageManager
            val hasFingerprint = pm.hasSystemFeature(PackageManager.FEATURE_FINGERPRINT)
            val hasFace = Build.VERSION.SDK_INT >= 29 && pm.hasSystemFeature(PackageManager.FEATURE_FACE)
            val hasIris = Build.VERSION.SDK_INT >= 29 && pm.hasSystemFeature(PackageManager.FEATURE_IRIS)
            val hasHardware = hasFingerprint || hasFace || hasIris

            val km = appContext.getSystemService(Context.KEYGUARD_SERVICE) as? KeyguardManager
            val secure = if (Build.VERSION.SDK_INT >= 23) {
                km?.isDeviceSecure ?: false
            } else {
                @Suppress("DEPRECATION")
                km?.isKeyguardSecure ?: false
            }

            when {
                hasHardware && secure -> "available"
                hasHardware && !secure -> "not_enrolled"
                else -> "unavailable"
            }
        } catch (e: Exception) {
            "unavailable"
        }
    }
}
