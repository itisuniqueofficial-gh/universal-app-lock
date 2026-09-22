package com.itisuniqueofficial.ual.platform

/**
 * ApplicationMonitor will observe which application is in the foreground so the
 * lock engine can decide whether a protected app must be challenged.
 *
 * STATUS: interface stub only — NOT implemented in this phase.
 *
 * The intended, third-party-safe implementation is based on
 * android.app.usage.UsageStatsManager (requires the user to grant Usage Access).
 * No foreground detection is performed yet. This interface documents the future
 * contract only and has no behavior.
 */
interface ApplicationMonitor {

    /** True once monitoring prerequisites (e.g. Usage Access) are satisfied. */
    fun isAvailable(): Boolean

    /** Begin observing foreground app changes. Not implemented yet. */
    fun start()

    /** Stop observing. Not implemented yet. */
    fun stop()
}
