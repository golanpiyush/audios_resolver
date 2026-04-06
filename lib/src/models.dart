// lib/src/models.dart
//
// Shared models for audios_resolver.

// ─────────────────────────────────────────────────────────────────────────────
// Audio source preference
// ─────────────────────────────────────────────────────────────────────────────

/// The preferred audio resolution backend.
///
/// The resolver will always attempt the preferred source first, silently
/// falling back to the other if it fails. The user's preference is restored
/// for the next track.
enum AudioSourcePreference {
  /// Use InnerTube Android clients directly (ANDROID_MUSIC → ANDROID_VR → …).
  /// Lower latency, no intermediate server. Default.
  innerTube,

  /// Use the YouTube Music API / web-style scraping path as primary.
  /// Slightly higher success rate on restricted regions, slower.
  ytMusicApi,
}

// ─────────────────────────────────────────────────────────────────────────────
// Result model
// ─────────────────────────────────────────────────────────────────────────────

/// A fully resolved audio stream for a YouTube video.
class AudiosResolverResult {
  final String videoId;
  final String url;
  final int itag;
  final String mimeType;
  final String codec;
  final int bitrate;
  final int? contentLength;
  final double? loudnessDb;
  final String clientUsed;
  final String userAgent;
  final DateTime expiresAt;

  /// Which backend actually resolved this URL. May differ from the requested
  /// [AudioSourcePreference] if an auto-override was triggered.
  final AudioSourcePreference resolvedVia;

  /// True if the resolver ignored the user's preference and used the other backend.
  final bool wasOverridden;

  const AudiosResolverResult({
    required this.videoId,
    required this.url,
    required this.itag,
    required this.mimeType,
    required this.codec,
    required this.bitrate,
    this.contentLength,
    this.loudnessDb,
    required this.clientUsed,
    required this.userAgent,
    required this.expiresAt,
    required this.resolvedVia,
    this.wasOverridden = false,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Reconstruct from a MethodChannel map (Android bridge).
  factory AudiosResolverResult.fromMap(Map<Object?, Object?> map) {
    return AudiosResolverResult(
      videoId: map['videoId'] as String,
      url: map['url'] as String,
      itag: map['itag'] as int,
      mimeType: map['mimeType'] as String,
      codec: map['codec'] as String,
      bitrate: map['bitrate'] as int,
      contentLength: map['contentLength'] as int?,
      loudnessDb: (map['loudnessDb'] as num?)?.toDouble(),
      clientUsed: map['clientUsed'] as String,
      userAgent: map['userAgent'] as String,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(map['expiresAt'] as int),
      resolvedVia: AudioSourcePreference.values.firstWhere(
        (e) => e.name == (map['resolvedVia'] as String),
        orElse: () => AudioSourcePreference.innerTube,
      ),
      wasOverridden: map['wasOverridden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'videoId': videoId,
        'url': url,
        'itag': itag,
        'mimeType': mimeType,
        'codec': codec,
        'bitrate': bitrate,
        'contentLength': contentLength,
        'loudnessDb': loudnessDb,
        'clientUsed': clientUsed,
        'userAgent': userAgent,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'resolvedVia': resolvedVia.name,
        'wasOverridden': wasOverridden,
      };

  @override
  String toString() => 'AudiosResolverResult(videoId: $videoId, itag: $itag, '
      'codec: $codec, bitrate: ${bitrate ~/ 1000}kbps, '
      'client: $clientUsed, via: ${resolvedVia.name}'
      '${wasOverridden ? " [OVERRIDE]" : ""})';
}
