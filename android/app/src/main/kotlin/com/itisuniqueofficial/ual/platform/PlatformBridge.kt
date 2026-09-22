package com.itisuniqueofficial.ual.platform

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import com.itisuniqueofficial.ual.lock.LockSessionManager
import com.itisuniqueofficial.ual.lock.ProtectedAppsStore
import com.itisuniqueofficial.ual.service.ForegroundMonitorService
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

/**
 * PlatformBridge is the single, narrow boundary between Flutter/Dart and the
 * native Android layer for Universal App Lock.
 *
 * Phase 6 surface: read-only diagnostics, application discovery, and permission
 * detection/settings navigation. NO app-lock enforcement, monitoring, overlay
 * drawing, or authentication is exposed. Security-sensitive operations remain
 * native and will be added behind explicitly reviewed methods in later phases.
 *
 * The bridge is versioned via [BRIDGE_VERSION].
 */
class PlatformBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        /** Semantic version of the platform bridge contract. */
        const val BRIDGE_VERSION = 5

        const val METHOD_CHANNEL = "com.itisuniqueofficial.ual/platform"
        const val EVENT_CHANNEL = "com.itisuniqueofficial.ual/platform_events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    private val discovery = ApplicationDiscoveryManager(context)
    private val usageAccess = UsageAccessManager(context)
    private val overlay = OverlayPermissionManager(context)
    private val auth = AuthenticationManager(context)
    private val protectedStore = ProtectedAppsStore(context)

    private val io = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    fun attach(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler(this@PlatformBridge)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    events?.success(mapOf("type" to "ready", "bridgeVersion" to BRIDGE_VERSION))
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
        }
    }

    fun detach() {
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
        eventSink = null
        io.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            // --- Diagnostics ---------------------------------------------------
            "getBridgeVersion" -> result.success(BRIDGE_VERSION)
            "getAndroidSdk" -> result.success(Build.VERSION.SDK_INT)
            "getPlatformInfo" -> result.success(platformInfo())
            "getAppVersion" -> result.success(appVersion())

            // --- Application discovery (offloaded to a background thread) -------
            "getInstalledApplications" -> {
                val includeSystem = call.argument<Boolean>("includeSystem") ?: false
                io.execute {
                    try {
                        val data = discovery.getInstalledApplications(includeSystem)
                        main.post { result.success(data) }
                    } catch (e: Exception) {
                        main.post { result.error("discovery_error", e.message, null) }
                    }
                }
            }
            "getApplicationIcon" -> {
                val pkg = call.argument<String>("packageName")
                val size = call.argument<Int>("sizePx") ?: 96
                if (pkg == null) {
                    result.error("bad_args", "packageName is required", null)
                } else {
                    io.execute {
                        val bytes = discovery.getApplicationIcon(pkg, size)
                        main.post { result.success(bytes) }
                    }
                }
            }

            // --- Permissions ---------------------------------------------------
            "isUsageAccessGranted" -> result.success(usageAccess.isGranted())
            "openUsageAccessSettings" -> result.success(usageAccess.openSettings())
            "isOverlayPermissionGranted" -> result.success(overlay.isGranted())
            "openOverlaySettings" -> result.success(overlay.openSettings())
            "getBiometricAvailability" -> result.success(auth.biometricAvailability())

            // --- Authentication (PIN; secret handling is native) ---------------
            "authHasPin" -> result.success(auth.hasPin())
            "authSetPin" -> {
                val pin = call.argument<String>("pin")
                if (pin == null) result.error("bad_args", "pin is required", null)
                else result.success(auth.setPin(pin))
            }
            "authVerifyPin" -> {
                val pin = call.argument<String>("pin")
                if (pin == null) result.error("bad_args", "pin is required", null)
                else result.success(auth.verifyPin(pin))
            }
            "authClearPin" -> result.success(auth.clearPin())

            // --- Protected apps (native source of truth) -----------------------
            "getProtectedApps" -> result.success(protectedStore.getProtected().toList())
            "setProtectedApps" -> {
                val list = call.argument<List<String>>("packages") ?: emptyList()
                protectedStore.setProtected(list)
                result.success(true)
            }

            // --- Monitoring / enforcement --------------------------------------
            "startMonitoring" -> {
                protectedStore.monitoringEnabled = true
                ForegroundMonitorService.start(context)
                result.success(true)
            }
            "stopMonitoring" -> {
                protectedStore.monitoringEnabled = false
                ForegroundMonitorService.stop(context)
                result.success(true)
            }
            "getMonitoringStatus" -> result.success(
                if (ForegroundMonitorService.isRunning) "running" else "stopped",
            )
            "grantUnlock" -> {
                val pkg = call.argument<String>("packageName")
                if (pkg == null) {
                    result.error("bad_args", "packageName is required", null)
                } else {
                    LockSessionManager.grant(pkg, protectedStore.relockTimeoutMs)
                    result.success(true)
                }
            }
            "setRelockPolicy" -> {
                (call.argument<Number>("relockTimeoutMs"))?.let {
                    protectedStore.relockTimeoutMs = it.toLong()
                }
                (call.argument<Boolean>("lockOnScreenOff"))?.let {
                    protectedStore.lockOnScreenOff = it
                }
                result.success(true)
            }

            // --- Self Lock (protect our own UI) --------------------------------
            "getSelfLockState" -> result.success(protectedStore.selfLockEnabled)
            "setSelfLock" -> {
                val enabled = call.argument<Boolean>("enabled") ?: false
                protectedStore.selfLockEnabled = enabled
                // Enabling from within the (already open) app grants an initial
                // session so the user is not immediately locked out.
                if (enabled) {
                    LockSessionManager.grant(context.packageName, protectedStore.selfLockTimeoutMs)
                } else {
                    LockSessionManager.invalidate(context.packageName)
                }
                result.success(true)
            }
            "setSelfLockPolicy" -> {
                (call.argument<Number>("relockTimeoutMs"))?.let {
                    protectedStore.selfLockTimeoutMs = it.toLong()
                }
                result.success(true)
            }

            else -> result.notImplemented()
        }
    }

    private fun platformInfo(): Map<String, Any?> = mapOf(
        "os" to "android",
        "sdkInt" to Build.VERSION.SDK_INT,
        "release" to Build.VERSION.RELEASE,
        "manufacturer" to Build.MANUFACTURER,
        "model" to Build.MODEL,
        "bridgeVersion" to BRIDGE_VERSION,
    )

    private fun appVersion(): Map<String, Any?> {
        return try {
            val pm = context.packageManager
            val pkg = context.packageName
            val info = pm.getPackageInfo(pkg, 0)
            val code: Long = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                info.longVersionCode
            } else {
                @Suppress("DEPRECATION")
                info.versionCode.toLong()
            }
            mapOf(
                "packageName" to pkg,
                "versionName" to (info.versionName ?: ""),
                "versionCode" to code,
            )
        } catch (e: PackageManager.NameNotFoundException) {
            mapOf("packageName" to context.packageName, "versionName" to "", "versionCode" to 0L)
        }
    }
}
