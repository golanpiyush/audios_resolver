package  com.golanpiyush.audios_resolver

import java.util.Date

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

data class AudioResolverResult(
    val videoId: String,
    val url: String,
    val itag: Int,
    val mimeType: String,
    val codec: String,
    val bitrate: Int,
    val contentLength: Int?,
    val loudnessDb: Double?,
    val clientUsed: String,
    val userAgent: String,
    val expiresAt: Date,
) {
    val isExpired: Boolean get() = Date().after(expiresAt)

    /** Serialise to a flat Map for the Flutter MethodChannel. */
    fun toMap(): Map<String, Any?> = mapOf(
        "videoId"       to videoId,
        "url"           to url,
        "itag"          to itag,
        "mimeType"      to mimeType,
        "codec"         to codec,
        "bitrate"       to bitrate,
        "contentLength" to contentLength,
        "loudnessDb"    to loudnessDb,
        "clientUsed"    to clientUsed,
        "userAgent"     to userAgent,
        "expiresAtMs"   to expiresAt.time,   // epoch ms — Dart: DateTime.fromMillisecondsSinceEpoch
    )

    override fun toString(): String =
        "AudioResolverResult(videoId=$videoId, itag=$itag, " +
        "codec=$codec, bitrate=${bitrate / 1000}kbps, client=$clientUsed)"
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal InnerTube client definition
// ─────────────────────────────────────────────────────────────────────────────

internal data class ITClient(
    val name: String,
    val clientName: String,
    val clientVersion: String,
    val apiKey: String,
    val androidSdkVersion: Int? = null,
    val userAgent: String,
    val playerParams: String? = null,
)