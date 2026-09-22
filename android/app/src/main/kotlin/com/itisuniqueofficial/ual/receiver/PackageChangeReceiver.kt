package com.itisuniqueofficial.ual.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.itisuniqueofficial.ual.lock.ProtectedAppsStore

/**
 * Removes a package from the protected list when it is fully uninstalled, so no
 * stale entries accumulate. A reinstall is NOT auto-trusted — the user must
 * re-select it (unless a future auto-lock-new-apps policy opts in).
 */
class PackageChangeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_PACKAGE_FULLY_REMOVED) return
        // A replacement (update) keeps EXTRA_REPLACING = true; ignore those.
        if (intent.getBooleanExtra(Intent.EXTRA_REPLACING, false)) return
        val pkg = intent.data?.schemeSpecificPart ?: return
        ProtectedAppsStore(context).remove(pkg)
    }
}
