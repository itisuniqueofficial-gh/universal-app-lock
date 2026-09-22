package com.itisuniqueofficial.ual.platform

import android.content.Context
import android.content.SharedPreferences
import android.util.Base64
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import java.security.MessageDigest
import java.security.SecureRandom
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.PBEKeySpec

/**
 * SecureCredentialStore persists the app PIN as a salted PBKDF2 hash inside
 * EncryptedSharedPreferences (encrypted at rest with a key held in the Android
 * Keystore). The plaintext PIN is never persisted; nothing here is ever logged.
 *
 * Threat model note: this protects the stored PIN at rest. Attempt/lockout
 * accounting (non-secret) is handled in the Dart layer.
 */
class SecureCredentialStore(context: Context) {

    companion object {
        private const val FILE = "ual_secure_credentials"
        private const val KEY_HASH = "pin_hash"
        private const val KEY_SALT = "pin_salt"
        private const val KEY_ITER = "pin_iterations"
        private const val ITERATIONS = 120_000
        private const val KEY_LENGTH_BITS = 256
        private const val SALT_BYTES = 16
    }

    private val prefs: SharedPreferences by lazy {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        EncryptedSharedPreferences.create(
            context,
            FILE,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM,
        )
    }

    fun hasPin(): Boolean = prefs.contains(KEY_HASH) && prefs.contains(KEY_SALT)

    fun setPin(pin: CharArray): Boolean {
        return try {
            val salt = ByteArray(SALT_BYTES).also { SecureRandom().nextBytes(it) }
            val hash = derive(pin, salt, ITERATIONS)
            prefs.edit()
                .putString(KEY_HASH, b64(hash))
                .putString(KEY_SALT, b64(salt))
                .putInt(KEY_ITER, ITERATIONS)
                .apply()
            wipe(hash)
            true
        } catch (e: Exception) {
            false
        } finally {
            pin.fill('\u0000')
        }
    }

    fun verifyPin(pin: CharArray): Boolean {
        return try {
            val storedHash = prefs.getString(KEY_HASH, null) ?: return false
            val storedSalt = prefs.getString(KEY_SALT, null) ?: return false
            val iterations = prefs.getInt(KEY_ITER, ITERATIONS)
            val computed = derive(pin, unb64(storedSalt), iterations)
            val ok = MessageDigest.isEqual(computed, unb64(storedHash))
            wipe(computed)
            ok
        } catch (e: Exception) {
            false
        } finally {
            pin.fill('\u0000')
        }
    }

    fun clearPin(): Boolean {
        return try {
            prefs.edit().remove(KEY_HASH).remove(KEY_SALT).remove(KEY_ITER).apply()
            true
        } catch (e: Exception) {
            false
        }
    }

    private fun derive(pin: CharArray, salt: ByteArray, iterations: Int): ByteArray {
        val spec = PBEKeySpec(pin, salt, iterations, KEY_LENGTH_BITS)
        try {
            val skf = SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256")
            return skf.generateSecret(spec).encoded
        } finally {
            spec.clearPassword()
        }
    }

    private fun b64(b: ByteArray) = Base64.encodeToString(b, Base64.NO_WRAP)
    private fun unb64(s: String) = Base64.decode(s, Base64.NO_WRAP)
    private fun wipe(b: ByteArray) = b.fill(0)
}
