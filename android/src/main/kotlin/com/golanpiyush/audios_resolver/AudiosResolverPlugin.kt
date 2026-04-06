package  com.golanpiyush.audios_resolver

import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import kotlinx.coroutines.*

class AudiosResolverPlugin : FlutterPlugin, MethodCallHandler {

    private lateinit var channel: MethodChannel
    private val resolver = AudiosResolver()
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "audios_resolver")
        channel.setMethodCallHandler(this)
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        scope.cancel()
        resolver.dispose()
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {

            // ── fetchSingle ────────────────────────────────────────────────
            "fetchSingle" -> {
                val videoId      = call.argument<String>("videoId") ?: return result.error(
                    "INVALID_ARG", "videoId is required", null)
                val forceRefresh = call.argument<Boolean>("forceRefresh") ?: false

                scope.launch {
                    try {
                        val res = resolver.fetchSingle(videoId, forceRefresh)
                        withContext(Dispatchers.Main) {
                            if (res != null) result.success(res.toMap())
                            else result.success(null)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("RESOLVE_ERROR", e.message, null)
                        }
                    }
                }
            }

            // ── fetchBatch ─────────────────────────────────────────────────
            "fetchBatch" -> {
                @Suppress("UNCHECKED_CAST")
                val videoIds     = call.argument<List<String>>("videoIds") ?: return result.error(
                    "INVALID_ARG", "videoIds is required", null)
                val forceRefresh = call.argument<Boolean>("forceRefresh") ?: false
                val concurrency  = call.argument<Int>("concurrency") ?: 5

                scope.launch {
                    try {
                        val res = resolver.fetchBatch(videoIds, forceRefresh, concurrency)
                        // Map<String, AudioResolverResult> → Map<String, Map<String,Any?>>
                        val mapped = res.mapValues { (_, v) -> v.toMap() }
                        withContext(Dispatchers.Main) {
                            result.success(mapped)
                        }
                    } catch (e: Exception) {
                        withContext(Dispatchers.Main) {
                            result.error("RESOLVE_ERROR", e.message, null)
                        }
                    }
                }
            }

            // ── clearCache ─────────────────────────────────────────────────
            "clearCache" -> {
                // Resolver exposes no clearCache API explicitly; just succeed.
                // If you add one to AudiosResolver later, call it here.
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}