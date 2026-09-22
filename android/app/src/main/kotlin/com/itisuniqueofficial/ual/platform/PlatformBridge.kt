package com.itisuniqueofficial.ual.platform

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * PlatformBridge is the single, narrow boundary between Flutter/Dart and the
 * native Android layer for Universal App Lock.
 *
 * SECURITY BOUNDARY
 * -----------------
 * In this phase the bridge exposes ONLY harmless, read-only diagnostic methods.
 * No privileged capabilities, no Samsung-only APIs, and no app-lock enforcement
 * are exposed. Future security-sensitive operations (monitoring, overlay,
 * authentication, secure storage, boot handling) will be added here behind
 * explicitly named, individually reviewed methods — never in Dart.
 *
 * The bridge is versioned via [BRIDGE_VERSION] so Dart and native can detect
 * incompatibilities as the surface grows.
 */
class PlatformBridge(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        /** Semantic version of the platform bridge contract. */
        const val BRIDGE_VERSION = 1

        const val METHOD_CHANNEL = "com.itisuniqueofficial.ual/platform"
        const val EVENT_CHANNEL = "com.itisuniqueofficial.ual/platform_events"
    }

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null
    private var eventSink: EventChannel.EventSink? = null

    fun attach(messenger: BinaryMessenger) {
        methodChannel = MethodChannel(messenger, METHOD_CHANNEL).apply {
            setMethodCallHandler(this@PlatformBridge)
        }
        eventChannel = EventChannel(messenger, EVENT_CHANNEL).apply {
            setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Emit a single, harmless "ready" capability event so the Dart
                    // side can verify the event channel is wired. No sensitive data.
                    events?.success(
                        mapOf(
                            "type" to "ready",
                            "bridgeVersion" to BRIDGE_VERSION,
                        )
                    )
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
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getBridgeVersion" -> result.success(BRIDGE_VERSION)
            "getAndroidSdk" -> result.success(Build.VERSION.SDK_INT)
            "getPlatformInfo" -> result.success(platformInfo())
            "getAppVersion" -> result.success(appVersion())
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
            mapOf(
                "packageName" to context.packageName,
                "versionName" to "",
                "versionCode" to 0L,
            )
        }
    }
}
