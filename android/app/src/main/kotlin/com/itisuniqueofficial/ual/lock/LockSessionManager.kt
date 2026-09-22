package com.itisuniqueofficial.ual.lock

import android.os.SystemClock
import java.util.concurrent.ConcurrentHashMap

/**
 * LockSessionManager holds temporary unlock sessions IN MEMORY only, so a valid
 * authenticated session never survives process death or reboot. Shared as a
 * process-wide singleton between the monitor service, the bridge, and LockActivity.
 */
object LockSessionManager {

    private data class Session(val grantedAtMs: Long, val timeoutMs: Long)

    private val sessions = ConcurrentHashMap<String, Session>()

    private fun now() = SystemClock.elapsedRealtime()

    /**
     * Grant an unlock for [pkg]. [timeoutMs] == 0 means the session stays valid
     * until it is explicitly invalidated (e.g. on app exit or screen off).
     */
    fun grant(pkg: String, timeoutMs: Long) {
        sessions[pkg] = Session(now(), timeoutMs)
    }

    fun isUnlocked(pkg: String): Boolean {
        val s = sessions[pkg] ?: return false
        if (s.timeoutMs > 0 && now() - s.grantedAtMs >= s.timeoutMs) {
            sessions.remove(pkg)
            return false
        }
        return true
    }

    fun invalidate(pkg: String) {
        sessions.remove(pkg)
    }

    fun invalidateAll() {
        sessions.clear()
    }
}

/**
 * Deterministic decision for whether a foreground package must be challenged.
 * Kept tiny and side-effect free so the logic is easy to reason about.
 */
object LockPolicyEngine {
    fun requiresAuthentication(
        foregroundPackage: String,
        ownPackage: String,
        isProtected: Boolean,
        hasValidSession: Boolean,
    ): Boolean {
        if (foregroundPackage == ownPackage) return false // never lock self
        if (!isProtected) return false
        return !hasValidSession
    }
}
