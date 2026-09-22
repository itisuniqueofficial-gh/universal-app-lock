package com.itisuniqueofficial.ual

import android.content.Intent
import com.itisuniqueofficial.ual.lock.LockSessionManager
import com.itisuniqueofficial.ual.lock.ProtectedAppsStore
import com.itisuniqueofficial.ual.platform.PlatformBridge
import com.itisuniqueofficial.ual.ui.LockActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Entry Activity for Universal App Lock.
 *
 * Hosts the Flutter UI, registers the [PlatformBridge], and enforces **Self Lock**:
 * if the user enabled Self Lock and there is no valid unlock session for our own
 * package, [LockActivity] is launched over this activity on resume. This is
 * loop-safe because the foreground monitor excludes our own package, and the
 * self-lock check only re-launches while locked (after a successful unlock a
 * session exists, so it does not fire again).
 */
class MainActivity : FlutterActivity() {

    private var platformBridge: PlatformBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platformBridge = PlatformBridge(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun onResume() {
        super.onResume()
        enforceSelfLock()
    }

    private fun enforceSelfLock() {
        val store = ProtectedAppsStore(this)
        if (store.selfLockEnabled && !LockSessionManager.isUnlocked(packageName)) {
            val intent = Intent(this, LockActivity::class.java).apply {
                putExtra(LockActivity.EXTRA_PACKAGE, packageName)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        platformBridge?.detach()
        platformBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
