package com.itisuniqueofficial.ual.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.itisuniqueofficial.ual.lock.LockSessionManager
import com.itisuniqueofficial.ual.lock.ProtectedAppsStore
import com.itisuniqueofficial.ual.service.ForegroundMonitorService

/**
 * Restarts foreground monitoring after a device reboot IF the user had enabled
 * it. Authenticated sessions never survive reboot: the in-memory session store
 * starts empty, and we clear it defensively here.
 */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_LOCKED_BOOT_COMPLETED
        ) {
            LockSessionManager.invalidateAll()
            val store = ProtectedAppsStore(context)
            if (store.monitoringEnabled && store.getProtected().isNotEmpty()) {
                ForegroundMonitorService.start(context)
            }
        }
    }
}
