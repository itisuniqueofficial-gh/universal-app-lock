package com.itisuniqueofficial.ual.service

import android.app.Service
import android.content.Intent
import android.os.IBinder

/**
 * LockOverlayService will (in a future phase) run as a foreground service and
 * present the lock challenge overlay when a protected app is brought to the
 * foreground.
 *
 * STATUS: stub only — NOT implemented and NOT registered in AndroidManifest.xml.
 *
 * This class performs no locking and is inert. It is intentionally not declared
 * as a <service> in the manifest yet, so it cannot run. It exists solely to
 * establish the package boundary for the future implementation, which will use
 * only third-party-safe APIs (foreground service + SYSTEM_ALERT_WINDOW granted
 * by the user). See docs/ARCHITECTURE.md and docs/SECURITY.md.
 */
class LockOverlayService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // No-op: overlay locking is not implemented in this phase.
        return START_NOT_STICKY
    }
}
