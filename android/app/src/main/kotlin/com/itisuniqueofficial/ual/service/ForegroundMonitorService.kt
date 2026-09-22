package com.itisuniqueofficial.ual.service

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.HandlerThread
import android.os.IBinder
import androidx.core.app.ServiceCompat
import com.itisuniqueofficial.ual.R
import com.itisuniqueofficial.ual.lock.LockPolicyEngine
import com.itisuniqueofficial.ual.lock.LockSessionManager
import com.itisuniqueofficial.ual.lock.ProtectedAppsStore
import com.itisuniqueofficial.ual.ui.LockActivity

/**
 * ForegroundMonitorService detects the current foreground application via
 * UsageStatsManager and launches [LockActivity] when a protected app is opened
 * without a valid unlock session. It runs as a foreground service so Android
 * keeps it alive; enforcement does not depend on the Flutter UI being open.
 *
 * NOTE (runtime, not device-verified here): launching the lock screen from the
 * background requires the "Display over other apps" permission (background
 * activity-start exemption) and Usage Access. Detection latency depends on the
 * Android version/OEM; this is a best-effort supported-API implementation.
 */
class ForegroundMonitorService : Service() {

    private lateinit var store: ProtectedAppsStore
    private var thread: HandlerThread? = null
    private var handler: Handler? = null
    private var lastForeground: String? = null
    private var screenReceiver: BroadcastReceiver? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        store = ProtectedAppsStore(this)
        startAsForeground()
        registerScreenReceiver()
        val t = HandlerThread("ual-monitor").also { it.start() }
        thread = t
        handler = Handler(t.looper).also { it.post(pollRunnable) }
        isRunning = true
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        return START_STICKY
    }

    private val pollRunnable = object : Runnable {
        override fun run() {
            poll()
            handler?.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    private fun poll() {
        try {
            val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
            val end = System.currentTimeMillis()
            val begin = end - LOOKBACK_MS
            val events = usm.queryEvents(begin, end)
            val e = UsageEvents.Event()
            var latestPkg: String? = null
            var latestTime = 0L
            while (events.hasNextEvent()) {
                events.getNextEvent(e)
                val isForeground =
                    e.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND ||
                        (Build.VERSION.SDK_INT >= 29 &&
                            e.eventType == UsageEvents.Event.ACTIVITY_RESUMED)
                if (isForeground && e.timeStamp >= latestTime) {
                    latestTime = e.timeStamp
                    latestPkg = e.packageName
                }
            }
            latestPkg?.let { handleForeground(it) }
        } catch (se: SecurityException) {
            // Usage Access was revoked; nothing to enforce until re-granted.
        } catch (ex: Exception) {
            // Never crash the monitor because of a transient query error.
        }
    }

    private fun handleForeground(pkg: String) {
        if (pkg == packageName) return // our own UI / LockActivity
        if (pkg == lastForeground) return
        val previous = lastForeground
        lastForeground = pkg

        // Re-lock the app we just left (lock-on-exit behavior).
        if (previous != null && store.isProtected(previous)) {
            LockSessionManager.invalidate(previous)
        }

        val mustLock = LockPolicyEngine.requiresAuthentication(
            foregroundPackage = pkg,
            ownPackage = packageName,
            isProtected = store.isProtected(pkg),
            hasValidSession = LockSessionManager.isUnlocked(pkg),
        )
        if (mustLock) launchLock(pkg)
    }

    private fun launchLock(pkg: String) {
        val intent = Intent(this, LockActivity::class.java).apply {
            putExtra(LockActivity.EXTRA_PACKAGE, pkg)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        try {
            startActivity(intent)
        } catch (ex: Exception) {
            // Background activity start may be blocked without overlay permission.
        }
    }

    private fun registerScreenReceiver() {
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == Intent.ACTION_SCREEN_OFF && store.lockOnScreenOff) {
                    LockSessionManager.invalidateAll()
                    lastForeground = null
                }
            }
        }
        registerReceiver(receiver, IntentFilter(Intent.ACTION_SCREEN_OFF))
        screenReceiver = receiver
    }

    private fun startAsForeground() {
        val mgr = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "App protection",
                NotificationManager.IMPORTANCE_LOW,
            )
            channel.description = "Keeps app protection active."
            mgr.createNotificationChannel(channel)
        }
        val notification: Notification = androidx.core.app.NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Universal App Lock")
            .setContentText("Protection is active")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setOngoing(true)
            .setPriority(androidx.core.app.NotificationCompat.PRIORITY_LOW)
            .build()

        val type = if (Build.VERSION.SDK_INT >= 34) {
            ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
        } else {
            0
        }
        ServiceCompat.startForeground(this, NOTIF_ID, notification, type)
    }

    override fun onDestroy() {
        isRunning = false
        handler?.removeCallbacksAndMessages(null)
        thread?.quitSafely()
        screenReceiver?.let { runCatching { unregisterReceiver(it) } }
        super.onDestroy()
    }

    companion object {
        const val CHANNEL_ID = "ual_monitor"
        const val NOTIF_ID = 4711
        const val POLL_INTERVAL_MS = 1000L
        const val LOOKBACK_MS = 10_000L

        @Volatile
        var isRunning: Boolean = false
            private set

        fun start(context: Context) {
            val intent = Intent(context, ForegroundMonitorService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, ForegroundMonitorService::class.java))
        }
    }
}
