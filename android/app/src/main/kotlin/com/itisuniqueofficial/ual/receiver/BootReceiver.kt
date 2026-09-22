package com.itisuniqueofficial.ual.receiver

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

/**
 * BootReceiver will (in a future phase) re-establish the lock engine after the
 * device restarts, if and only if the user has enabled locking.
 *
 * STATUS: stub only — NOT implemented and NOT registered in AndroidManifest.xml.
 *
 * This receiver is inert: it is not declared in the manifest, holds no
 * RECEIVE_BOOT_COMPLETED permission, and does nothing on receive. It exists only
 * to establish the package boundary for the future implementation.
 */
class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        // No-op: boot handling is not implemented in this phase.
    }
}
