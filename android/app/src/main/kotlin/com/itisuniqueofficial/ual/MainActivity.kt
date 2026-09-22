package com.itisuniqueofficial.ual

import com.itisuniqueofficial.ual.platform.PlatformBridge
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

/**
 * Entry Activity for Universal App Lock.
 *
 * This class intentionally contains no security logic. Its only responsibility
 * is to host the Flutter UI and register the [PlatformBridge], which exposes a
 * narrow, versioned set of diagnostic platform methods to Dart.
 *
 * The app-lock engine (monitoring, overlay, authentication, storage, boot) is
 * NOT implemented in this phase. See docs/ARCHITECTURE.md.
 */
class MainActivity : FlutterActivity() {

    private var platformBridge: PlatformBridge? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        platformBridge = PlatformBridge(applicationContext).also {
            it.attach(flutterEngine.dartExecutor.binaryMessenger)
        }
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        platformBridge?.detach()
        platformBridge = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
