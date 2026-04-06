package com.golanpiyush.audios_resolver

import io.ktor.client.*
import io.ktor.client.engine.okhttp.*
import io.ktor.client.plugins.*
import io.ktor.client.plugins.contentnegotiation.*
import io.ktor.client.request.*
import io.ktor.client.statement.*
import io.ktor.http.*
import io.ktor.serialization.kotlinx.json.*
import kotlinx.coroutines.*
import kotlinx.serialization.json.*
import java.util.Date
import java.util.concurrent.ConcurrentHashMap

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

private const val ANDROID_MUSIC_API_KEY = "AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
private const val ANDROID_API_KEY       = "AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"

private const val PLAYER_ENDPOINT = "https://music.youtube.com/youtubei/v1/player"
private const val CONFIG_ENDPOINT = "https://music.youtube.com/youtubei/v1/config"

/** InnerTube Android client ladder — tried in order, exactly as in the Dart source. */
private val INNERTUBE_CLIENTS = listOf(
    ITClient(
        name          = "ANDROID_MUSIC",
        clientName    = "ANDROID_MUSIC",
        clientVersion = "5.26.1",
        apiKey        = ANDROID_MUSIC_API_KEY,
        androidSdkVersion = 33,
        userAgent     = "com.google.android.apps.youtube.music/5.26.1 (Linux; U; Android 13; en_US) gzip",
    ),
    ITClient(
        name          = "ANDROID_VR",
        clientName    = "ANDROID_VR",
        clientVersion = "1.60.19",
        apiKey        = ANDROID_API_KEY,
        androidSdkVersion = 33,
        userAgent     = "com.google.android.apps.youtube.vr.oculus/1.60.19 (Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip",
    ),
    ITClient(
        name          = "ANDROID",
        clientName    = "ANDROID",
        clientVersion = "17.36.4",
        apiKey        = ANDROID_API_KEY,
        androidSdkVersion = 30,
        userAgent     = "com.google.android.youtube/17.36.4 (Linux; U; Android 11) gzip",
        playerParams  = "CgIQBg",
    ),
    ITClient(
        name          = "ANDROID_TESTSUITE",
        clientName    = "ANDROID_TESTSUITE",
        clientVersion = "1.9",
        apiKey        = ANDROID_API_KEY,
        androidSdkVersion = 33,
        userAgent     = "com.google.android.youtube/1.9 (Linux; U; Android 13; en_US) gzip",
    ),
)

/** Preferred itags in priority order: opus 160kbps, opus 70kbps, m4a 128kbps. */
private val PREFERRED_ITAGS = listOf(251, 250, 140)

// ─────────────────────────────────────────────────────────────────────────────
// AudiosResolver — Kotlin core
// ─────────────────────────────────────────────────────────────────────────────

class AudiosResolver(
    timeoutMs: Long = 15_000L,
) {
    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val http = HttpClient(OkHttp) {
        install(HttpTimeout) {
            requestTimeoutMillis = timeoutMs
            connectTimeoutMillis = timeoutMs
        }
        install(ContentNegotiation) { json(json) }
    }

    // Cache: videoId → result
    private val cache = ConcurrentHashMap<String, AudioResolverResult>()

    // In-flight deduplication: videoId → Deferred
    private val inFlight = ConcurrentHashMap<String, Deferred<AudioResolverResult?>>()

    @Volatile private var visitorData: String? = null
    private val visitorDataMutex = kotlinx.coroutines.sync.Mutex()

    // ── Public API ─────────────────────────────────────────────────────────

    /**
     * Resolve a single video ID to a direct audio URL.
     * Results are cached until the URL expires.
     */
    suspend fun fetchSingle(
        videoId: String,
        forceRefresh: Boolean = false,
    ): AudioResolverResult? = coroutineScope {
        if (forceRefresh) {
            cache.remove(videoId)
            inFlight.remove(videoId)
        }

        cache[videoId]?.takeIf { !it.isExpired }?.let {
            log("⚡ [$videoId] Cache hit")
            return@coroutineScope it
        }

        // Deduplicate concurrent requests for the same ID.
        val deferred = inFlight.getOrPut(videoId) {
            async { resolve(videoId) }.also { d ->
                d.invokeOnCompletion { inFlight.remove(videoId) }
            }
        }
        deferred.await()
    }

    /**
     * Resolve multiple video IDs concurrently (max 30, up to [concurrency] at once).
     * Returns only the IDs that succeeded.
     */
    suspend fun fetchBatch(
        videoIds: List<String>,
        forceRefresh: Boolean = false,
        concurrency: Int = 5,
    ): Map<String, AudioResolverResult> = coroutineScope {
        val ids = videoIds.take(30)
        log("🎵 Batch resolving ${ids.size} videos (concurrency: $concurrency)")

        val results = ConcurrentHashMap<String, AudioResolverResult>()
        val toFetch = mutableListOf<String>()

        if (!forceRefresh) {
            for (id in ids) {
                val cached = cache[id]
                if (cached != null && !cached.isExpired) results[id] = cached
                else toFetch += id
            }
        } else {
            toFetch += ids
        }

        if (toFetch.isEmpty()) return@coroutineScope results.toMap()

        ensureVisitorData()

        toFetch.chunked(concurrency).forEachIndexed { chunkIdx, chunk ->
            val deferreds = chunk.map { id ->
                id to async { fetchSingle(id, forceRefresh) }
            }
            deferreds.forEach { (id, d) ->
                d.await()?.let { results[id] = it }
            }
            if (chunkIdx < toFetch.chunked(concurrency).size - 1) {
                delay(200)
            }
        }

        log("✅ Batch complete: ${results.size}/${ids.size} succeeded")
        results.toMap()
    }

    fun dispose() {
        http.close()
        cache.clear()
        inFlight.clear()
    }

    // ── Visitor data ───────────────────────────────────────────────────────

    private suspend fun ensureVisitorData(): String? {
        if (visitorData != null) return visitorData
        visitorDataMutex.lock()
        try {
            if (visitorData != null) return visitorData   // double-check after lock
            visitorData = fetchVisitorData()
        } finally {
            visitorDataMutex.unlock()
        }
        return visitorData
    }

    private suspend fun fetchVisitorData(): String? {
        return try {
            log("🔑 Fetching visitor_data from config endpoint...")
            val body = buildJsonObject {
                put("context", buildJsonObject {
                    put("client", buildJsonObject {
                        put("clientName", "ANDROID_MUSIC")
                        put("clientVersion", "5.26.1")
                        put("androidSdkVersion", 33)
                        put("osName", "Android")
                        put("osVersion", "13")
                        put("hl", "en")
                        put("gl", "US")
                    })
                })
            }

            val response: HttpResponse = http.post(CONFIG_ENDPOINT) {
                parameter("key", ANDROID_MUSIC_API_KEY)
                parameter("prettyPrint", "false")
                headers {
                    append("User-Agent",
                        "com.google.android.apps.youtube.music/5.26.1 (Linux; U; Android 13; en_US) gzip")
                    append("X-YouTube-Client-Name", "21")
                    append("X-YouTube-Client-Version", "5.26.1")
                    append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                }
                setBody(body.toString())
            }

            if (response.status.value != 200) {
                log("⚠️ config endpoint returned ${response.status.value}")
                return null
            }

            val respJson = json.parseToJsonElement(response.bodyAsText()).jsonObject
            val vd = respJson["responseContext"]
                ?.jsonObject?.get("visitorData")?.jsonPrimitive?.contentOrNull
                ?: respJson["visitorData"]?.jsonPrimitive?.contentOrNull

            if (vd != null) {
                log("✅ Got visitor_data: ${vd.take(10)}...")
            } else {
                log("⚠️ No visitor_data in config response")
            }
            vd
        } catch (e: Exception) {
            log("⚠️ visitor_data fetch failed: $e")
            null
        }
    }

    // ── Core resolver ──────────────────────────────────────────────────────

    private suspend fun resolve(videoId: String): AudioResolverResult? {
        val vd = ensureVisitorData()

        for (client in INNERTUBE_CLIENTS) {
            try {
                log("📱 [$videoId] Trying ${client.name}...")
                // ANDROID_MUSIC intentionally skips visitorData (matches Dart source)
                val effectiveVd = if (client.name == "ANDROID_MUSIC") null else vd
                val result = callPlayerEndpoint(videoId, client, visitorData = effectiveVd)
                if (result != null) {
                    log("✅ [$videoId] ${client.name} succeeded — ${result.codec} ${result.bitrate / 1000}kbps")
                    cache[videoId] = result
                    return result
                }
            } catch (e: Exception) {
                val msg = e.message ?: ""
                if (msg.contains("400")) {
                    log("⚠️ [$videoId] ${client.name} HTTP 400 — skipping")
                } else {
                    log("⚠️ [$videoId] ${client.name} error: $e")
                }
            }
        }

        log("❌ [$videoId] All InnerTube clients exhausted")
        return null
    }

    // ── Player endpoint ────────────────────────────────────────────────────

    private suspend fun callPlayerEndpoint(
        videoId: String,
        client: ITClient,
        visitorData: String?,
    ): AudioResolverResult? {
        val body = buildPlayerBody(videoId, client, visitorData)

        val response: HttpResponse = http.post(PLAYER_ENDPOINT) {
            parameter("key", client.apiKey)
            parameter("prettyPrint", "false")
            headers {
                append(HttpHeaders.ContentType, ContentType.Application.Json.toString())
                append(HttpHeaders.Accept, ContentType.Application.Json.toString())
                append("User-Agent", client.userAgent)
                append("X-YouTube-Client-Name", clientCode(client.clientName))
                append("X-YouTube-Client-Version", client.clientVersion)
            }
            setBody(body.toString())
        }

        if (response.status.value != 200) {
            throw Exception("HTTP ${response.status.value}")
        }

        val respJson = json.parseToJsonElement(response.bodyAsText()).jsonObject

        val status = respJson["playabilityStatus"]
            ?.jsonObject?.get("status")?.jsonPrimitive?.contentOrNull ?: ""

        if (status != "OK") {
            log("⚠️ [$videoId] ${client.name} playabilityStatus: $status")
            if (status == "LOGIN_REQUIRED") {
                log("🔄 [$videoId] Invalidating visitor_data due to LOGIN_REQUIRED")
                this.visitorData = null
            }
            return null
        }

        val formats = respJson["streamingData"]
            ?.jsonObject?.get("adaptiveFormats")
            ?.jsonArray?.mapNotNull { it.jsonObject }
            ?: emptyList()

        val audioFormats = formats.filter { f ->
            val mime = f["mimeType"]?.jsonPrimitive?.contentOrNull ?: ""
            val url  = f["url"]?.jsonPrimitive?.contentOrNull
            val hasCipher = f.containsKey("signatureCipher") || f.containsKey("cipher")
            mime.startsWith("audio/") && !url.isNullOrEmpty() && !hasCipher
        }

        if (audioFormats.isEmpty()) {
            log("⚠️ [$videoId] ${client.name} no direct-URL audio formats")
            return null
        }

        // Pick best format — prefer itags 251 → 250 → 140, else highest bitrate.
        val best: JsonObject = run {
            var found: JsonObject? = null
            for (itag in PREFERRED_ITAGS) {
                found = audioFormats.firstOrNull {
                    it["itag"]?.jsonPrimitive?.intOrNull == itag
                }
                if (found != null) break
            }
            found ?: audioFormats.maxByOrNull {
                it["bitrate"]?.jsonPrimitive?.intOrNull ?: 0
            }!!
        }

        val url = best["url"]?.jsonPrimitive?.contentOrNull ?: return null
        if (!isUsableUrl(url)) {
            log("⚠️ [$videoId] ${client.name} URL failed sanity check")
            return null
        }

        val contentLength = best["contentLength"]?.jsonPrimitive?.contentOrNull?.toIntOrNull()
            ?: best["contentLength"]?.jsonPrimitive?.intOrNull
        if (contentLength != null && contentLength <= 0) {
            log("⚠️ [$videoId] contentLength=0, skipping")
            return null
        }

        val mimeType = best["mimeType"]?.jsonPrimitive?.contentOrNull ?: ""

        return AudioResolverResult(
            videoId       = videoId,
            url           = url,
            itag          = best["itag"]?.jsonPrimitive?.intOrNull ?: 0,
            mimeType      = mimeType,
            codec         = extractCodec(mimeType),
            bitrate       = best["bitrate"]?.jsonPrimitive?.intOrNull ?: 0,
            contentLength = contentLength,
            loudnessDb    = best["loudnessDb"]?.jsonPrimitive?.doubleOrNull,
            clientUsed    = client.name,
            userAgent     = client.userAgent,
            expiresAt     = parseExpiry(url),
        )
    }

    // ── Helpers ────────────────────────────────────────────────────────────

    private fun buildPlayerBody(
        videoId: String,
        client: ITClient,
        visitorData: String?,
    ): JsonObject = buildJsonObject {
        put("videoId", videoId)
        client.playerParams?.let { put("params", it) }
        put("context", buildJsonObject {
            put("client", buildJsonObject {
                put("clientName", client.clientName)
                put("clientVersion", client.clientVersion)
                client.androidSdkVersion?.let { sdk ->
                    put("androidSdkVersion", sdk)
                    put("osName", "Android")
                    put("osVersion", if (sdk >= 33) "13" else "11")
                    put("platform", "MOBILE")
                }
                put("hl", "en")
                put("gl", "US")
                put("utcOffsetMinutes", 0)
                visitorData?.let { put("visitorData", it) }
            })
        })
        put("playbackContext", buildJsonObject {
            put("contentPlaybackContext", buildJsonObject {
                put("html5Preference", "HTML5_PREF_WANTS")
            })
        })
        put("contentCheckOk", true)
        put("racyCheckOk", true)
    }

    private fun isUsableUrl(url: String): Boolean = try {
        val uri = java.net.URI(url)
        uri.host?.contains("googlevideo.com") == true &&
            url.contains("expire=")
    } catch (_: Exception) { false }

    private fun extractCodec(mimeType: String): String =
        Regex("""codecs="([^"]+)"""").find(mimeType)?.groupValues?.get(1) ?: "unknown"

    private fun parseExpiry(url: String): Date = try {
        val expire = Regex("""[?&]expire=(\d+)""").find(url)?.groupValues?.get(1)
        if (expire != null) Date(expire.toLong() * 1000L)
        else Date(System.currentTimeMillis() + 6 * 3600 * 1000L)
    } catch (_: Exception) {
        Date(System.currentTimeMillis() + 6 * 3600 * 1000L)
    }

    private fun clientCode(name: String): String = when (name) {
        "ANDROID_MUSIC"     -> "21"
        "ANDROID"           -> "3"
        "ANDROID_TESTSUITE" -> "30"
        "ANDROID_VR"        -> "28"
        "IOS"               -> "5"
        "WEB_REMIX"         -> "67"
        else                -> "3"
    }

    private fun log(msg: String) = println("[AudiosResolver] $msg")
}