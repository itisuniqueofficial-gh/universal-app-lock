package com.itisuniqueofficial.ual.platform

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings

/**
 * OverlayPermissionManager detects and helps the user grant the "Display over
 * other apps" permission (SYSTEM_ALERT_WINDOW).
 *
 * IMPORTANT: this permission is NOT used to draw anything in this phase. It will
 * be required later so the lock screen can appear above protected applications.
 * Nothing is drawn or enforced here.
 */
class OverlayPermissionManager(private val context: Context) {

    fun isGranted(): Boolean {
        return if (Build.VERSION.SDK_INT >= 23) {
            try {
                Settings.canDrawOverlays(context)
            } catch (e: Exception) {
                false
            }
        } else {
            // Pre-Marshmallow: granted at install time.
            true
        }
    }

    /** Opens the overlay-permission settings screen. Returns true if launched. */
    fun openSettings(): Boolean {
        val scoped = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:${context.packageName}"),
        ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (tryStart(scoped)) return true

        val general = Intent(Settings.ACTION_MANAGE_OVERLAY_PERMISSION)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        if (tryStart(general)) return true

        val fallback = Intent(Settings.ACTION_SETTINGS)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        return tryStart(fallback)
    }

    private fun tryStart(intent: Intent): Boolean {
        return try {
            context.startActivity(intent)
            true
        } catch (e: Exception) {
            false
        }
    }
}
