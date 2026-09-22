package com.itisuniqueofficial.ual.ui

import android.os.Build
import io.flutter.embedding.android.FlutterActivity

/**
 * LockActivity is the native authentication surface shown over a protected app.
 *
 * It is a real Android Activity (launched natively by the monitor), not just a
 * Flutter route: it is declared with its own task, excluded from recents, and
 * carries the locked package via the Flutter initial route ("lock/<pkg>"). The
 * Flutter side renders the sharp PIN lock screen and, on success, grants an
 * unlock session and finishes the activity. Marked FLAG_SECURE to keep the
 * locked surface out of screenshots/recents thumbnails.
 */
class LockActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        // Keep the lock surface out of screenshots and the recents thumbnail.
        window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
        }
        super.onCreate(savedInstanceState)
    }

    override fun getInitialRoute(): String {
        val pkg = intent?.getStringExtra(EXTRA_PACKAGE)
        return if (!pkg.isNullOrEmpty()) "lock/$pkg" else "lock/"
    }

    // The locked app stays behind us; do not allow back-press to dismiss the
    // lock without authenticating. The Flutter side also blocks pop.
    @Suppress("MissingSuperCall", "GestureBackNavigation", "OVERRIDE_DEPRECATION")
    override fun onBackPressed() {
        // no-op: authentication is required to leave.
    }

    companion object {
        const val EXTRA_PACKAGE = "ual_locked_package"
    }
}
