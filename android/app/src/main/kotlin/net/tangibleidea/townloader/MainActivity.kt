package net.tangibleidea.townloader

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

// 다른 앱의 공유(ACTION_SEND, text/plain)로 들어온 링크를 Dart 로 넘긴다.
class MainActivity : FlutterActivity() {
    private var shareChannel: MethodChannel? = null

    // Dart 가 준비되기 전에 들어온 공유 링크. `getInitialShare` 호출 때 한 번 넘기고 비운다.
    private var pendingShare: String? = null
    private var dartReady = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingShare = sharedText(intent)

        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SHARE_CHANNEL)
            .apply {
                setMethodCallHandler { call, result ->
                    if (call.method == "getInitialShare") {
                        dartReady = true
                        result.success(pendingShare)
                        pendingShare = null
                    } else {
                        result.notImplemented()
                    }
                }
            }
    }

    // 앱이 이미 떠 있을 때(singleTop) 새 공유가 오면 여기로 들어온다.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val text = sharedText(intent) ?: return
        if (dartReady) {
            shareChannel?.invokeMethod("onShare", text)
        } else {
            pendingShare = text
        }
    }

    private fun sharedText(intent: Intent?): String? {
        if (intent?.action != Intent.ACTION_SEND) return null
        if (intent.type?.startsWith("text/") != true) return null
        return intent.getStringExtra(Intent.EXTRA_TEXT)?.takeIf { it.isNotBlank() }
    }

    private companion object {
        const val SHARE_CHANNEL = "townloader/share"
    }
}
