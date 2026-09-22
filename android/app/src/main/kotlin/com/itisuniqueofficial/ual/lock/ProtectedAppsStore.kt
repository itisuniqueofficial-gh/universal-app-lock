package com.itisuniqueofficial.ual.lock

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey

/**
 * ProtectedAppsStore is the NATIVE source of truth for which packages are
 * protected, plus the (non-secret) lock policy. It is encrypted at rest with a
 * Keystore-backed key so configuration is not stored in plaintext.
 *
 * The Flutter UI writes here via the platform bridge; the ForegroundMonitor
 * reads here directly, so enforcement works even when the Flutter UI is closed.
 * The app's own package can never be added (no self-lock).
 */
class ProtectedAppsStore(context: Context) {

    private val appContext = context.applicationContext

    private val prefs: SharedPreferences by lazy {
        val key = MasterKey.Builder(appContext)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            appContext,
            FILE,
            key,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    fun getProtected(): Set<String> =
        prefs.getStringSet(KEY_PACKAGES, emptySet())?.toSet() ?: emptySet()

    fun setProtected(packages: Collection<String>) {
        val cleaned = packages
            .map { it.trim() }
            .filter { it.isNotEmpty() && it != appContext.packageName }
            .toSet()
        prefs.edit().putStringSet(KEY_PACKAGES, cleaned).apply()
    }

    fun isProtected(pkg: String): Boolean = getProtected().contains(pkg)

    fun remove(pkg: String) {
        val next = getProtected().toMutableSet()
        if (next.remove(pkg)) prefs.edit().putStringSet(KEY_PACKAGES, next).apply()
    }

    // --- Lock policy (non-secret) --------------------------------------------

    /** Re-lock timeout in ms; 0 means "lock on app exit" (no time-based grace). */
    var relockTimeoutMs: Long
        get() = prefs.getLong(KEY_TIMEOUT, 0L)
        set(v) = prefs.edit().putLong(KEY_TIMEOUT, v).apply()

    var lockOnScreenOff: Boolean
        get() = prefs.getBoolean(KEY_SCREEN_OFF, true)
        set(v) = prefs.edit().putBoolean(KEY_SCREEN_OFF, v).apply()

    /** Whether the user has enabled monitoring (used by BootReceiver). */
    var monitoringEnabled: Boolean
        get() = prefs.getBoolean(KEY_MONITORING, false)
        set(v) = prefs.edit().putBoolean(KEY_MONITORING, v).apply()

    companion object {
        private const val FILE = "ual_protection_config"
        private const val KEY_PACKAGES = "protected_packages"
        private const val KEY_TIMEOUT = "relock_timeout_ms"
        private const val KEY_SCREEN_OFF = "lock_on_screen_off"
        private const val KEY_MONITORING = "monitoring_enabled"
    }
}
