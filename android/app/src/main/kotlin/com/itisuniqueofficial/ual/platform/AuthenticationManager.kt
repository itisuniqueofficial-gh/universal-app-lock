package com.itisuniqueofficial.ual.platform

/**
 * AuthenticationManager will verify the user's identity before unlocking a
 * protected app (PIN and/or androidx.biometric BiometricPrompt).
 *
 * STATUS: interface stub only — NOT implemented in this phase.
 *
 * Security requirements for the future implementation (see docs/SECURITY.md):
 *  - Never store plaintext credentials; PINs must be salted+hashed.
 *  - Use the Android Keystore for sensitive cryptographic material.
 *  - Never log authentication secrets.
 * No authentication is performed yet; this interface has no behavior.
 */
interface AuthenticationManager {

    /** Whether device biometric hardware is present and enrolled. */
    fun canAuthenticateWithBiometrics(): Boolean

    /** Whether an app credential (e.g. PIN) has been configured. */
    fun hasAppCredential(): Boolean
}
