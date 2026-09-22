package com.itisuniqueofficial.ual.platform

/**
 * PlatformAdapter is the abstraction that will isolate Android version and
 * vendor differences (including an optional, NON-privileged Samsung
 * compatibility seam) behind a single interface.
 *
 * STATUS: interface stub only — no implementations exist in this phase.
 *
 * Implementations MUST rely exclusively on Android APIs available to normal
 * third-party applications. They MUST NOT use Samsung privileged/system APIs
 * (e.g. WRITE_SECURE_SETTINGS, INTERACT_ACROSS_USERS, MANAGE_USERS) nor depend
 * on the Samsung system app-lock package. See docs/SECURITY.md and
 * docs/FORENSIC-ANALYSIS.md.
 */
interface PlatformAdapter {

    /** Human-readable adapter identifier, e.g. "generic-android". */
    val adapterId: String

    /** Whether the current device/OS exposes the capabilities this adapter needs. */
    fun isSupported(): Boolean
}
