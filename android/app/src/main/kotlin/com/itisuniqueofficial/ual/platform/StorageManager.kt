package com.itisuniqueofficial.ual.platform

/**
 * StorageManager will provide secure, app-local persistence for the protected
 * apps list, lock policy, and credential material.
 *
 * STATUS: interface stub only — NOT implemented in this phase.
 *
 * The intended implementation uses androidx.security EncryptedSharedPreferences
 * (backed by the Android Keystore). State is app-local; the app does NOT use
 * system Settings.Secure (which requires privileged permissions unavailable to
 * third-party apps — see docs/FORENSIC-ANALYSIS.md). No storage is implemented yet.
 */
interface StorageManager {

    /** Whether secure storage has been initialized. */
    fun isInitialized(): Boolean
}
