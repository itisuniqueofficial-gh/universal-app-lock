package com.itisuniqueofficial.ual.platform

import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.content.pm.ResolveInfo
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.os.Build
import java.io.ByteArrayOutputStream

/**
 * ApplicationDiscoveryManager enumerates user-launchable applications using only
 * supported, third-party-safe Android APIs (PackageManager launcher query).
 *
 * It deliberately enumerates apps that expose a MAIN/LAUNCHER activity — the set
 * of apps that can meaningfully be locked — which does NOT require the flagged
 * QUERY_ALL_PACKAGES permission (a <queries> entry in the manifest is enough).
 * Non-launchable / all-package enumeration is intentionally out of scope here.
 *
 * No enforcement, monitoring, or locking happens in this class.
 */
class ApplicationDiscoveryManager(private val context: Context) {

    private val pm: PackageManager get() = context.packageManager

    /** Returns launchable applications as plain maps for the platform channel. */
    fun getInstalledApplications(includeSystem: Boolean): List<Map<String, Any?>> {
        val launcher = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER)
        val flags = PackageManager.MATCH_DISABLED_COMPONENTS or PackageManager.MATCH_ALL

        val resolveInfos: List<ResolveInfo> = try {
            if (Build.VERSION.SDK_INT >= 33) {
                pm.queryIntentActivities(
                    launcher,
                    PackageManager.ResolveInfoFlags.of(flags.toLong()),
                )
            } else {
                @Suppress("DEPRECATION")
                pm.queryIntentActivities(launcher, flags)
            }
        } catch (e: Exception) {
            emptyList()
        }

        val seen = HashSet<String>()
        val result = ArrayList<Map<String, Any?>>(resolveInfos.size)

        for (ri in resolveInfos) {
            val ai = ri.activityInfo?.applicationInfo ?: continue
            val pkg = ai.packageName ?: continue
            if (pkg == context.packageName) continue // never list ourselves
            if (!seen.add(pkg)) continue

            val isSystem = (ai.flags and ApplicationInfo.FLAG_SYSTEM) != 0 ||
                (ai.flags and ApplicationInfo.FLAG_UPDATED_SYSTEM_APP) != 0
            if (isSystem && !includeSystem) continue

            val label = try {
                pm.getApplicationLabel(ai)?.toString()
            } catch (e: Exception) {
                null
            } ?: pkg

            var versionName = ""
            var versionCode = 0L
            try {
                val pi = pm.getPackageInfo(pkg, 0)
                versionName = pi.versionName ?: ""
                versionCode = if (Build.VERSION.SDK_INT >= 28) {
                    pi.longVersionCode
                } else {
                    @Suppress("DEPRECATION")
                    pi.versionCode.toLong()
                }
            } catch (e: Exception) {
                // Incomplete metadata is tolerated; keep defaults.
            }

            result.add(
                mapOf(
                    "packageName" to pkg,
                    "applicationName" to label,
                    "isSystemApp" to isSystem,
                    "isEnabled" to ai.enabled,
                    "launchable" to true,
                    "versionName" to versionName,
                    "versionCode" to versionCode,
                ),
            )
        }

        result.sortBy { (it["applicationName"] as String).lowercase() }
        return result
    }

    /** Returns the app icon as PNG bytes (square [sizePx]), or null on failure. */
    fun getApplicationIcon(packageName: String, sizePx: Int): ByteArray? {
        return try {
            val drawable = pm.getApplicationIcon(packageName)
            drawableToPng(drawable, if (sizePx <= 0) 96 else sizePx)
        } catch (e: Exception) {
            null
        }
    }

    private fun drawableToPng(drawable: Drawable, size: Int): ByteArray {
        val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        drawable.setBounds(0, 0, canvas.width, canvas.height)
        drawable.draw(canvas)
        val out = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, out)
        bitmap.recycle()
        return out.toByteArray()
    }
}
