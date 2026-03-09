package com.swmansion.detour

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch

data class DetourConfig(
    val apiKey: String,
    val appID: String,
    val shouldUseClipboard: Boolean,
    val linkProcessingMode: String
)

class DetourFlutterPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    EventChannel.StreamHandler,
    PluginRegistry.NewIntentListener {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private lateinit var applicationContext: Context

    private var config: DetourConfig? = null
    private var storage: DetourStorage? = null
    private val analytics = DetourAnalytics()
    private var eventSink: EventChannel.EventSink? = null
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var isFirstSessionHandled = false

    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        methodChannel = MethodChannel(binding.binaryMessenger, "detour_flutter_plugin")
        methodChannel.setMethodCallHandler(this)
        eventChannel = EventChannel(binding.binaryMessenger, "detour_flutter_plugin/links")
        eventChannel.setStreamHandler(this)

        // Collect user agent on main thread
        mainHandler.post {
            try {
                val ua = android.webkit.WebView(applicationContext).settings.userAgentString ?: ""
                DetourFingerprint.setCachedUserAgent(ua)
            } catch (_: Exception) {}
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
    }

    // MARK: - ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activityBinding?.removeOnNewIntentListener(this)
        activity = null
        activityBinding = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addOnNewIntentListener(this)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeOnNewIntentListener(this)
        activity = null
        activityBinding = null
    }

    // Intercept runtime deep links
    override fun onNewIntent(intent: Intent): Boolean {
        val data = intent.data ?: return false
        val rawUrl = data.toString()
        if (rawUrl.isEmpty() || rawUrl == "about:blank") return false

        val cfg = config ?: return false
        val sink = eventSink ?: return false

        scope.launch(Dispatchers.IO) {
            val parsed = DetourNetwork.parseUrl(rawUrl)
            val resultMap = buildResultMap(parsed)
            mainHandler.post { sink.success(resultMap) }
        }
        return true
    }

    // MARK: - EventChannel.StreamHandler

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    // MARK: - MethodCallHandler

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> {
                val args = call.arguments as? Map<*, *>
                val apiKey = args?.get("apiKey") as? String
                val appID = args?.get("appID") as? String
                if (apiKey == null || appID == null) {
                    result.error("INVALID_ARGS", "apiKey and appID are required", null)
                    return
                }
                val shouldUseClipboard = args["shouldUseClipboard"] as? Boolean ?: true
                val linkProcessingMode = args["linkProcessingMode"] as? String ?: "all"
                config = DetourConfig(apiKey, appID, shouldUseClipboard, linkProcessingMode)
                storage = DetourStorage(applicationContext)
                result.success(null)
            }

            "resolveInitialLink" -> {
                val cfg = config
                val store = storage
                if (cfg == null || store == null) {
                    result.error("NOT_CONFIGURED", "Call configure() first", null)
                    return
                }

                scope.launch(Dispatchers.IO) {
                    val resultData = resolveInitialLinkInternal(cfg, store)
                    mainHandler.post { result.success(resultData) }
                }
            }

            "processLink" -> {
                val args = call.arguments as? Map<*, *>
                val url = args?.get("url") as? String
                if (url == null) {
                    result.error("INVALID_ARGS", "url is required", null)
                    return
                }
                val cfg = config
                scope.launch(Dispatchers.IO) {
                    val parsed = DetourNetwork.parseUrl(url)
                    val resultMap = buildResultMap(parsed)
                    // If web URL with single-segment path, try resolving short link
                    val finalMap = if (cfg != null && shouldResolveShortLink(parsed)) {
                        val resolved = DetourNetwork.resolveShortLink(cfg.apiKey, cfg.appID, url)
                        if (resolved != null) buildResultMap(resolved) else resultMap
                    } else {
                        resultMap
                    }
                    mainHandler.post { result.success(finalMap) }
                }
            }

            "resetSession" -> {
                val args = call.arguments as? Map<*, *>
                val allowDeferredRetry = args?.get("allowDeferredRetry") as? Boolean ?: false
                isFirstSessionHandled = false
                if (allowDeferredRetry) {
                    storage?.resetFirstEntrance()
                }
                result.success(null)
            }

            "mountAnalytics" -> {
                val cfg = config
                val store = storage
                if (cfg == null || store == null) {
                    result.error("NOT_CONFIGURED", "Call configure() first", null)
                    return
                }
                val deviceId = store.getOrCreateDeviceId()
                analytics.mount(cfg.apiKey, cfg.appID, deviceId)
                result.success(null)
            }

            "unmountAnalytics" -> {
                analytics.unmount()
                result.success(null)
            }

            "logEvent" -> {
                val args = call.arguments as? Map<*, *>
                val eventName = args?.get("eventName") as? String
                if (eventName == null) {
                    result.error("INVALID_ARGS", "eventName is required", null)
                    return
                }
                @Suppress("UNCHECKED_CAST")
                val data = args["data"] as? Map<String, Any>
                analytics.logEvent(eventName, data)
                result.success(null)
            }

            "logRetention" -> {
                val args = call.arguments as? Map<*, *>
                val eventName = args?.get("eventName") as? String
                if (eventName == null) {
                    result.error("INVALID_ARGS", "eventName is required", null)
                    return
                }
                analytics.logRetention(eventName)
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // MARK: - Helpers

    private suspend fun resolveInitialLinkInternal(
        cfg: DetourConfig,
        store: DetourStorage
    ): Map<String, Any?> {
        if (isFirstSessionHandled) {
            return emptyResultMap()
        }

        val mode = cfg.linkProcessingMode

        // Check for runtime deep link in current activity intent
        if (mode != "deferred-only") {
            val intentData = activity?.intent?.data
            if (intentData != null) {
                val rawUrl = intentData.toString()
                if (rawUrl.isNotEmpty() && rawUrl != "about:blank") {
                    store.markFirstEntrance()
                    isFirstSessionHandled = true
                    val parsed = DetourNetwork.parseUrl(rawUrl)
                    return buildResultMap(parsed)
                }
            }
        }

        // Deferred: only on first entrance
        if (!store.isFirstEntrance()) {
            isFirstSessionHandled = true
            return emptyResultMap()
        }

        store.markFirstEntrance()
        isFirstSessionHandled = true

        // Try deterministic install referrer first
        val clickId = getInstallReferrerClickId(cfg)
        if (clickId != null) {
            val parsed = DetourNetwork.parseUrl(clickId, typeOverride = "deferred")
            return buildResultMap(parsed)
        }

        // Probabilistic fingerprint
        val fingerprint = DetourFingerprint.buildFingerprint(applicationContext)
        val matched = DetourNetwork.matchLink(cfg.apiKey, cfg.appID, fingerprint)
        return if (matched != null) buildResultMap(matched) else emptyResultMap()
    }

    private fun getInstallReferrerClickId(cfg: DetourConfig): String? {
        var result: String? = null
        val latch = java.util.concurrent.CountDownLatch(1)
        DetourFingerprint.getInstallReferrerClickId(applicationContext) { clickId ->
            result = clickId
            latch.countDown()
        }
        latch.await(5, java.util.concurrent.TimeUnit.SECONDS)
        return result
    }

    private fun shouldResolveShortLink(parsed: DetourNetwork.DetourResultData): Boolean {
        if (parsed.type == "scheme") return false
        val url = try { java.net.URI(parsed.url).toURL() } catch (e: Exception) { return false }
        val path = url.path ?: return false
        val segments = path.split("/").filter { it.isNotEmpty() }
        return segments.size == 1
    }

    private fun buildResultMap(data: DetourNetwork.DetourResultData): Map<String, Any?> {
        return mapOf(
            "processed" to true,
            "link" to mapOf(
                "url" to data.url,
                "route" to data.route,
                "pathname" to data.pathname,
                "params" to data.params,
                "type" to data.type
            )
        )
    }

    private fun emptyResultMap(): Map<String, Any?> {
        return mapOf("processed" to true, "link" to null)
    }
}
